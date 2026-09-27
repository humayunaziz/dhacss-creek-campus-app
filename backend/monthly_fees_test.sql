-- Transactional integration test: all fixture data and bills are rolled back.
begin;
insert into auth.users(id,email,email_confirmed_at) values
 ('a1000000-0000-0000-0000-000000000001','fee-admin@example.test',now()),
 ('a1000000-0000-0000-0000-000000000002','fee-parent@example.test',now()),
 ('a1000000-0000-0000-0000-000000000003','fee-outsider@example.test',now());
insert into public.campuses(id,code,name) values
 ('a2000000-0000-0000-0000-000000000001','__FEE_TEST__','Fee test'),
 ('a2000000-0000-0000-0000-000000000002','__FEE_OTHER__','Other campus');
insert into public.staff_memberships(user_id,role,campus_id) values('a1000000-0000-0000-0000-000000000001','campus_admin','a2000000-0000-0000-0000-000000000001');
insert into public.students(id,campus_id,full_name,admission_number,class_name,status)
select ('a3000000-0000-0000-0000-00000000000'||n)::uuid,'a2000000-0000-0000-0000-000000000001','Test child '||n,'FEE-TEST-'||n,case when n=2 then 'Two' else 'One' end,case n when 3 then 'inactive' when 4 then 'transferred' when 5 then 'suspended' when 6 then 'left' else 'active' end from generate_series(1,6) n;
insert into public.parent_student_links(parent_id,student_id) values('a1000000-0000-0000-0000-000000000002','a3000000-0000-0000-0000-000000000001');
set local role authenticated;
select set_config('request.jwt.claim.sub','a1000000-0000-0000-0000-000000000001',true);
do $$ declare p jsonb;r jsonb;bill uuid;begin
 p:=public.preview_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10');
 if (p->>'missing')::int<>2 or (p->>'excluded')::int<>4 then raise exception 'FAIL eligibility/missing rates';end if;
 begin
  perform public.generate_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10',p->>'token');
  raise exception 'FAIL missing rates accepted';
 exception when raise_exception then if SQLERRM not like 'Set rates%' then raise;end if;end;
 perform public.save_fee_rate('a2000000-0000-0000-0000-000000000001','One','2026-08-01',1000,'Tuition');
 perform public.save_fee_rate('a2000000-0000-0000-0000-000000000001','One','2026-10-01',9000,'Future tuition');
 perform public.save_fee_rate('a2000000-0000-0000-0000-000000000001','Two','2026-09-01',2000,'Tuition');
 begin
  perform public.generate_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10',p->>'token');
  raise exception 'FAIL stale preview accepted';
 exception when raise_exception then if SQLERRM not like 'Records changed%' then raise;end if;end;
 p:=public.preview_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10');
 if (p->>'total')::numeric<>3000 then raise exception 'FAIL effective rates';end if;
 r:=public.generate_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10',p->>'token');
 if (r->>'generated')::int<>2 then raise exception 'FAIL generation';end if;
 p:=public.preview_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10');
 r:=public.generate_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10',p->>'token');
 if (r->>'generated')::int<>0 or (r->>'skipped_existing')::int<>2 then raise exception 'FAIL duplicate skip';end if;
 perform public.save_fee_rate('a2000000-0000-0000-0000-000000000001','One','2026-08-01',1500,'Revised tuition');
 select id into bill from public.monthly_fee_bills where student_id='a3000000-0000-0000-0000-000000000001';
 if (select amount from public.monthly_fee_bills where id=bill)<>1000 then raise exception 'FAIL snapshot changed';end if;
 begin update public.monthly_fee_bills set amount=1 where id=bill;raise exception 'FAIL direct bill edit';exception when insufficient_privilege then null;end;
 perform public.void_monthly_fee(bill,'Correct rate');
 p:=public.preview_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10');
 r:=public.generate_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10',p->>'token');
 if (r->>'generated')::int<>1 or (r->>'total')::numeric<>1500 then raise exception 'FAIL replacement';end if;
 begin perform public.preview_monthly_fees('a2000000-0000-0000-0000-000000000002','2026-09-01','2026-09-10');raise exception 'FAIL cross-campus access';exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claim.sub','a1000000-0000-0000-0000-000000000002',true);
do $$ begin
 if (select count(*) from public.monthly_fee_bills)<>2 then raise exception 'FAIL parent bill scope';end if;
 if exists(select 1 from public.fee_rates) then raise exception 'FAIL parent reads rates';end if;
 begin perform public.preview_monthly_fees('a2000000-0000-0000-0000-000000000001','2026-09-01','2026-09-10');raise exception 'FAIL parent can generate';exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claim.sub','a1000000-0000-0000-0000-000000000003',true);
do $$ begin
 if exists(select 1 from public.monthly_fee_bills) then raise exception 'FAIL unrelated user sees bills';end if;
end $$;
reset role;
rollback;
select 'PASS: status eligibility, missing rates, effective rates, stale preview, generation, duplicate skip, immutable snapshots, void/rebill, admin campus scope, parent scope and unrelated-user denial. Fixtures rolled back.' as result;
