begin;
create table public.fee_rates (
 id uuid primary key default gen_random_uuid(), campus_id uuid not null references public.campuses(id),
 class_name text not null check(length(trim(class_name)) between 1 and 50),
 effective_month date not null check(extract(day from effective_month)=1),
 amount numeric(12,2) not null check(amount>=0 and amount<=10000000),
 description text not null check(length(trim(description)) between 1 and 120),
 updated_by uuid not null references auth.users(id), updated_at timestamptz not null default now(),
 unique(campus_id,class_name,effective_month)
);
create table public.monthly_fee_bills (
 id uuid primary key default gen_random_uuid(), bill_number bigint generated always as identity unique,
 campus_id uuid not null references public.campuses(id), student_id uuid not null,
 billing_month date not null check(extract(day from billing_month)=1), due_date date not null check(due_date>=billing_month),
 student_name text not null, admission_number text not null, class_name text not null,
 description text not null, amount numeric(12,2) not null check(amount>=0 and amount<=10000000), currency text not null default 'PKR' check(currency='PKR'),
 created_by uuid not null references auth.users(id),created_at timestamptz not null default now(),
 voided_at timestamptz,voided_by uuid references auth.users(id),void_reason text,
 foreign key(student_id,campus_id) references public.students(id,campus_id),
 check((voided_at is null and voided_by is null and void_reason is null) or (voided_at is not null and voided_by is not null and length(trim(void_reason)) between 3 and 500))
);
create unique index monthly_fee_once on public.monthly_fee_bills(student_id,billing_month) where voided_at is null;
create index fee_bills_campus_month on public.monthly_fee_bills(campus_id,billing_month);
create index fee_rates_updated_by on public.fee_rates(updated_by);
create index fee_bills_created_by on public.monthly_fee_bills(created_by);
create index fee_bills_voided_by on public.monthly_fee_bills(voided_by);
alter table public.fee_rates enable row level security;
alter table public.monthly_fee_bills enable row level security;
revoke all on public.fee_rates,public.monthly_fee_bills from public,anon,authenticated;
grant select on public.fee_rates,public.monthly_fee_bills to authenticated;
create policy fee_rates_admin_read on public.fee_rates for select to authenticated using(private.can_manage_campus(campus_id));
create policy fee_bills_read on public.monthly_fee_bills for select to authenticated using(private.can_manage_campus(campus_id) or exists(select 1 from public.parent_student_links l where l.student_id=monthly_fee_bills.student_id and l.parent_id=(select auth.uid())));
create function private.save_fee_rate(target_campus uuid,target_class text,from_month date,monthly_amount numeric,fee_description text) returns void
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or not private.can_manage_campus(target_campus) then raise exception 'Not authorized' using errcode='42501';end if;
 if from_month is null or extract(day from from_month)<>1 or monthly_amount is null or monthly_amount<0 or monthly_amount>10000000 or monthly_amount<>round(monthly_amount,2) or monthly_amount::text='NaN' then raise exception 'Enter a valid month and amount with at most two decimal places';end if;
 if not exists(select 1 from public.students where campus_id=target_campus and class_name=trim(target_class)) then raise exception 'Select an existing class';end if;
 perform pg_advisory_xact_lock(hashtextextended(target_campus::text,72));
 insert into public.fee_rates(campus_id,class_name,effective_month,amount,description,updated_by)
 values(target_campus,trim(target_class),from_month,monthly_amount,trim(fee_description),auth.uid())
 on conflict(campus_id,class_name,effective_month) do update set amount=excluded.amount,description=excluded.description,updated_by=auth.uid(),updated_at=now();
end $$;
create function private.preview_monthly_fees(target_campus uuid,fee_month date,pay_by date) returns jsonb
language plpgsql security definer set search_path='' as $$
declare items jsonb; result jsonb;
begin
 if auth.uid() is null or not private.can_manage_campus(target_campus) then raise exception 'Not authorized' using errcode='42501';end if;
 if fee_month is null or extract(day from fee_month)<>1 or pay_by is null or pay_by<fee_month then raise exception 'Select a billing month and a due date on or after its first day';end if;
 select coalesce(jsonb_agg(jsonb_build_object('student_id',s.id,'student_name',s.full_name,'admission_number',s.admission_number,'class_name',s.class_name,'amount',r.amount,'description',r.description,'result',case when b.id is not null then 'already_billed' when r.id is null then 'missing_rate' else 'ready' end) order by s.admission_number,s.id),'[]'::jsonb)
 into items from public.students s
 left join lateral(select * from public.fee_rates f where f.campus_id=s.campus_id and f.class_name=s.class_name and f.effective_month<=fee_month order by f.effective_month desc limit 1) r on true
 left join public.monthly_fee_bills b on b.student_id=s.id and b.billing_month=fee_month and b.voided_at is null
 where s.campus_id=target_campus and s.status='active';
 result:=jsonb_build_object('campus_id',target_campus,'month',fee_month,'due_date',pay_by,'items',items,
 'ready',(select count(*) from jsonb_array_elements(items) x where x->>'result'='ready'),
 'missing',(select count(*) from jsonb_array_elements(items) x where x->>'result'='missing_rate'),
 'existing',(select count(*) from jsonb_array_elements(items) x where x->>'result'='already_billed'),
 'excluded',(select count(*) from public.students where campus_id=target_campus and status<>'active'),
 'total',coalesce((select sum((x->>'amount')::numeric) from jsonb_array_elements(items) x where x->>'result'='ready'),0));
 return result||jsonb_build_object('token',md5(result::text));
end $$;
create function private.generate_monthly_fees(target_campus uuid,fee_month date,pay_by date,preview_token text) returns jsonb
language plpgsql security definer set search_path='' as $$
declare p jsonb; n integer;
begin
 if auth.uid() is null or not private.can_manage_campus(target_campus) then raise exception 'Not authorized' using errcode='42501';end if;
 perform pg_advisory_xact_lock(hashtextextended(target_campus::text,72));
 -- Prevent status/class changes while the reviewed snapshot is committed.
 perform 1 from public.students where campus_id=target_campus for share;
 p:=private.preview_monthly_fees(target_campus,fee_month,pay_by);
 if preview_token is null or preview_token<>p->>'token' then raise exception 'Records changed. Refresh the preview before generating bills';end if;
 if (p->>'missing')::int>0 then raise exception 'Set rates for every active class before generating';end if;
 insert into public.monthly_fee_bills(campus_id,student_id,billing_month,due_date,student_name,admission_number,class_name,description,amount,created_by)
 select target_campus,(x->>'student_id')::uuid,fee_month,pay_by,x->>'student_name',x->>'admission_number',x->>'class_name',x->>'description',(x->>'amount')::numeric,auth.uid()
 from jsonb_array_elements(p->'items') x where x->>'result'='ready';
 get diagnostics n=row_count;
 return jsonb_build_object('generated',n,'total',p->'total','skipped_existing',p->'existing');
end $$;
create function private.void_monthly_fee(bill_id uuid,reason text) returns void
language plpgsql security definer set search_path='' as $$
declare c uuid;
begin
 select campus_id into c from public.monthly_fee_bills where id=bill_id;
 if auth.uid() is null or c is null or not private.can_manage_campus(c) then raise exception 'Not authorized' using errcode='42501';end if;
 if reason is null or length(trim(reason)) not between 3 and 500 then raise exception 'Enter a reason (3–500 characters)';end if;
 perform pg_advisory_xact_lock(hashtextextended(c::text,72));
 update public.monthly_fee_bills set voided_at=now(),voided_by=auth.uid(),void_reason=trim(reason) where id=bill_id and voided_at is null;
 if not found then raise exception 'Bill is already void';end if;
end $$;
create function public.save_fee_rate(target_campus uuid,target_class text,from_month date,monthly_amount numeric,fee_description text) returns void language sql security invoker set search_path='' as $$ select private.save_fee_rate(target_campus,target_class,from_month,monthly_amount,fee_description); $$;
create function public.preview_monthly_fees(target_campus uuid,fee_month date,pay_by date) returns jsonb language sql security invoker set search_path='' as $$ select private.preview_monthly_fees(target_campus,fee_month,pay_by); $$;
create function public.generate_monthly_fees(target_campus uuid,fee_month date,pay_by date,preview_token text) returns jsonb language sql security invoker set search_path='' as $$ select private.generate_monthly_fees(target_campus,fee_month,pay_by,preview_token); $$;
create function public.void_monthly_fee(bill_id uuid,reason text) returns void language sql security invoker set search_path='' as $$ select private.void_monthly_fee(bill_id,reason); $$;
revoke all on function private.save_fee_rate(uuid,text,date,numeric,text),private.preview_monthly_fees(uuid,date,date),private.generate_monthly_fees(uuid,date,date,text),private.void_monthly_fee(uuid,text),public.save_fee_rate(uuid,text,date,numeric,text),public.preview_monthly_fees(uuid,date,date),public.generate_monthly_fees(uuid,date,date,text),public.void_monthly_fee(uuid,text) from public,anon,authenticated;
grant execute on function private.save_fee_rate(uuid,text,date,numeric,text),private.preview_monthly_fees(uuid,date,date),private.generate_monthly_fees(uuid,date,date,text),private.void_monthly_fee(uuid,text),public.save_fee_rate(uuid,text,date,numeric,text),public.preview_monthly_fees(uuid,date,date),public.generate_monthly_fees(uuid,date,date,text),public.void_monthly_fee(uuid,text) to authenticated;
commit;
