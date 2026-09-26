begin;
create table public.student_accounts (
 user_id uuid primary key references auth.users(id), student_id uuid not null unique references public.students(id)
);
alter table public.student_accounts enable row level security;
revoke all on public.student_accounts from public,anon,authenticated;
grant select,insert,delete on public.student_accounts to authenticated;
create policy student_account_read on public.student_accounts for select to authenticated using(user_id=(select auth.uid()) or private.can_manage_student(student_id));
create policy student_account_add on public.student_accounts for insert to authenticated with check(private.can_manage_student(student_id));
create policy student_account_remove on public.student_accounts for delete to authenticated using(private.can_manage_student(student_id));
create function private.is_student_family(target uuid) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and (exists(select 1 from public.parent_student_links where student_id=target and parent_id=auth.uid()) or exists(select 1 from public.student_accounts where student_id=target and user_id=auth.uid()));
$$;
create function private.read_school_class(campus uuid, class_label text) returns boolean language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and (private.can_manage_campus(campus) or exists(select 1 from public.teacher_assignments a where a.user_id=auth.uid() and a.campus_id=campus and (class_label is null or a.class_name=class_label) and current_date between a.starts_on and a.ends_on) or exists(select 1 from public.students s where s.campus_id=campus and (class_label is null or s.class_name=class_label) and private.is_student_family(s.id)));
$$;
revoke all on function private.is_student_family(uuid),private.read_school_class(uuid,text) from public,anon,authenticated;
grant execute on function private.is_student_family(uuid),private.read_school_class(uuid,text) to authenticated;
create policy student_self_read on public.students for select to authenticated using(private.is_student_family(id));
create policy student_campus_read on public.campuses for select to authenticated using(private.read_school_class(id,null));
create policy student_attendance_read on public.attendance for select to authenticated using(private.is_student_family(student_id));
create policy student_homework_read on public.homework for select to authenticated using(private.read_school_class(campus_id,class_name));
create policy student_fee_read on public.monthly_fee_bills for select to authenticated using(private.is_student_family(student_id));
-- Shared school publications. Transport is published route information, never simulated GPS.
create table public.school_publications (
 id uuid primary key default gen_random_uuid(), campus_id uuid not null references public.campuses(id),
 class_name text check(length(trim(class_name)) between 1 and 50),
 kind text not null check(kind in ('notice','event','timetable','exam','transport','document')),
 title text not null check(length(trim(title)) between 1 and 200),
 body text not null check(length(trim(body)) between 1 and 10000),
 starts_on date, ends_on date, check(ends_on is null or (starts_on is not null and ends_on>=starts_on)),
 created_by uuid not null default auth.uid() references auth.users(id),created_at timestamptz not null default now()
);
create index school_publications_scope on public.school_publications(campus_id,class_name,kind,created_at);
create index school_publications_author on public.school_publications(created_by);
alter table public.school_publications enable row level security;
revoke all on public.school_publications from public,anon,authenticated;
grant select,insert,delete on public.school_publications to authenticated;
grant update(title,body,starts_on,ends_on) on public.school_publications to authenticated;
create policy publications_read on public.school_publications for select to authenticated using(private.read_school_class(campus_id,class_name));
create policy publications_insert on public.school_publications for insert to authenticated with check(private.can_manage_campus(campus_id) and created_by=(select auth.uid()));
create policy publications_update on public.school_publications for update to authenticated using(private.can_manage_campus(campus_id)) with check(private.can_manage_campus(campus_id));
create policy publications_delete on public.school_publications for delete to authenticated using(private.can_manage_campus(campus_id));
create table public.student_results (
 id uuid primary key default gen_random_uuid(), student_id uuid not null references public.students(id),
 exam_name text not null check(length(trim(exam_name)) between 1 and 120),subject text not null check(length(trim(subject)) between 1 and 100),
 exam_date date not null, marks numeric(8,2) not null check(marks>=0),total numeric(8,2) not null check(total>0 and marks<=total),
 remarks text not null default '' check(length(remarks)<=2000),created_by uuid not null default auth.uid() references auth.users(id),created_at timestamptz not null default now(),
 unique(student_id,exam_name,subject,exam_date)
);
create index student_results_author on public.student_results(created_by);
alter table public.student_results enable row level security;
revoke all on public.student_results from public,anon,authenticated;
grant select,insert,delete on public.student_results to authenticated;
grant update(marks,total,remarks) on public.student_results to authenticated;
create policy results_read on public.student_results for select to authenticated using(private.can_record_student(student_id) or private.is_student_family(student_id));
create policy results_insert on public.student_results for insert to authenticated with check(private.can_record_student(student_id) and created_by=(select auth.uid()));
create policy results_update on public.student_results for update to authenticated using(private.can_record_student(student_id)) with check(private.can_record_student(student_id));
create policy results_delete on public.student_results for delete to authenticated using(private.can_record_student(student_id));
create table public.leave_requests (
 id uuid primary key default gen_random_uuid(),student_id uuid not null references public.students(id),
 requested_by uuid not null default auth.uid() references auth.users(id), starts_on date not null,ends_on date not null check(ends_on>=starts_on and ends_on<=starts_on+90),
 reason text not null check(length(trim(reason)) between 3 and 2000),status text not null default 'pending' check(status in ('pending','approved','rejected','cancelled')),
 response text not null default '' check(length(response)<=2000),reviewed_by uuid references auth.users(id),reviewed_at timestamptz,created_at timestamptz not null default now()
);
create index leave_requests_student on public.leave_requests(student_id,starts_on);
create index leave_requests_author on public.leave_requests(requested_by);
create index leave_requests_reviewer on public.leave_requests(reviewed_by);
alter table public.leave_requests enable row level security;
revoke all on public.leave_requests from public,anon,authenticated;
grant select,insert on public.leave_requests to authenticated;
create policy leave_read on public.leave_requests for select to authenticated using(private.is_student_family(student_id) or private.can_record_student(student_id));
create policy leave_insert on public.leave_requests for insert to authenticated with check(private.is_student_family(student_id) and requested_by=(select auth.uid()) and status='pending' and response='' and reviewed_by is null and reviewed_at is null and starts_on>=(now() at time zone 'Asia/Karachi')::date);
create function private.review_school_leave(request_id uuid,decision text,note text) returns void language plpgsql security definer set search_path='' as $$
declare r public.leave_requests;
begin
 select * into r from public.leave_requests where id=request_id for update;
 if auth.uid() is null or r.id is null then raise exception 'Not authorized' using errcode='42501';end if;
 if decision='cancelled' then
  if r.requested_by<>auth.uid() or not private.is_student_family(r.student_id) then raise exception 'Not authorized' using errcode='42501';end if;
 elsif decision in ('approved','rejected') then
  if not private.can_record_student(r.student_id) then raise exception 'Not authorized' using errcode='42501';end if;
 else raise exception 'Invalid decision';end if;
 if r.status<>'pending' then raise exception 'Only pending requests can be changed';end if;
 if decision='rejected' and length(trim(coalesce(note,'')))<3 then raise exception 'Enter a rejection reason';end if;
 update public.leave_requests set status=decision,response=trim(coalesce(note,'')),reviewed_by=auth.uid(),reviewed_at=now() where id=request_id;
end $$;
create function public.review_school_leave(request_id uuid,decision text,note text) returns void language sql security invoker set search_path='' as $$select private.review_school_leave(request_id,decision,note);$$;
revoke all on function private.review_school_leave(uuid,text,text),public.review_school_leave(uuid,text,text) from public,anon,authenticated;
grant execute on function private.review_school_leave(uuid,text,text),public.review_school_leave(uuid,text,text) to authenticated;
create table public.school_messages (
 id uuid primary key default gen_random_uuid(),student_id uuid not null references public.students(id),
 sender_id uuid not null default auth.uid() references auth.users(id),
 body text not null check(length(trim(body)) between 1 and 4000),created_at timestamptz not null default now()
);
create index school_messages_student on public.school_messages(student_id,created_at);
create index school_messages_sender on public.school_messages(sender_id);
alter table public.school_messages enable row level security;
revoke all on public.school_messages from public,anon,authenticated;
grant select,insert on public.school_messages to authenticated;
create policy messages_read on public.school_messages for select to authenticated using(private.is_student_family(student_id) or private.can_record_student(student_id));
create policy messages_insert on public.school_messages for insert to authenticated with check(sender_id=(select auth.uid()) and (private.is_student_family(student_id) or private.can_record_student(student_id)));
-- Homework corrections stay within the existing assigned-class authorization.
grant update(subject,title,instructions,due_date),delete on public.homework to authenticated;
create policy homework_update on public.homework for update to authenticated using(private.can_manage_campus(campus_id) or private.can_teach(campus_id,class_name)) with check(private.can_manage_campus(campus_id) or private.can_teach(campus_id,class_name));
create policy homework_delete on public.homework for delete to authenticated using(private.can_manage_campus(campus_id) or private.can_teach(campus_id,class_name));
commit;
