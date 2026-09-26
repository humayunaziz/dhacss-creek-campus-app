-- Add student lifecycle and dated academic-year teacher assignments.
begin;
alter table public.students add column status text not null default 'active'
 check (status in ('active','transferred','suspended','inactive','left'));
grant update(status) on public.students to authenticated;
-- No existing teacher assignments at deployment. Require explicit year and dates.
alter table public.teacher_assignments add column academic_year text not null check(length(trim(academic_year)) between 1 and 30),
 add column starts_on date not null, add column ends_on date not null,
 add constraint assignment_dates_valid check(ends_on >= starts_on and ends_on <= starts_on + 730);
alter table public.teacher_assignments drop constraint teacher_assignments_user_id_campus_id_class_name_key;
alter table public.teacher_assignments add constraint assignment_year_unique unique(user_id,campus_id,class_name,academic_year);
create or replace function private.can_teach(campus uuid, class_label text) returns boolean
language sql stable security invoker set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.teacher_assignments a
 where a.user_id=auth.uid() and a.campus_id=campus and a.class_name=class_label
 and current_date between a.starts_on and a.ends_on);
$$;
create or replace function private.can_record_student(target uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.students s where s.id=target and
 (private.can_manage_campus(s.campus_id) or exists(select 1 from public.teacher_assignments a
 where a.user_id=auth.uid() and a.campus_id=s.campus_id and a.class_name=s.class_name
 and current_date between a.starts_on and a.ends_on)));
$$;
create function private.can_record_student_on(target uuid, day date) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.students s where s.id=target and
 (private.can_manage_campus(s.campus_id) or exists(select 1 from public.teacher_assignments a
 where a.user_id=auth.uid() and a.campus_id=s.campus_id and a.class_name=s.class_name
 and current_date between a.starts_on and a.ends_on and day between a.starts_on and a.ends_on)));
$$;
revoke all on function private.can_record_student_on(uuid,date) from public,anon,authenticated;
grant execute on function private.can_record_student_on(uuid,date) to authenticated;
alter policy teacher_campuses_read on public.campuses using(exists(select 1 from public.teacher_assignments a where a.campus_id=campuses.id and a.user_id=(select auth.uid()) and current_date between a.starts_on and a.ends_on));
alter policy attendance_insert on public.attendance with check(private.can_record_student_on(student_id,attendance_date) and recorded_by=(select auth.uid()));
alter policy attendance_update on public.attendance using(private.can_record_student_on(student_id,attendance_date)) with check(private.can_record_student_on(student_id,attendance_date) and recorded_by=(select auth.uid()));
drop function public.assign_teacher(text,uuid,text);
drop function private.assign_teacher(text,uuid,text);
create function private.assign_teacher(teacher_email text, target_campus uuid, target_class text, target_year text, year_start date, year_end date) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid;
begin
 if auth.uid() is null or not private.can_manage_campus(target_campus) then raise exception 'Not authorized' using errcode='42501'; end if;
 if target_year is null or length(trim(target_year)) not between 1 and 30 or year_start is null or year_end is null or year_end < year_start or year_end > year_start + 730 then raise exception 'Enter an academic year and valid start/end dates (maximum two years)'; end if;
 if not exists(select 1 from public.students where campus_id=target_campus and class_name=trim(target_class)) then raise exception 'Choose an existing class in this campus'; end if;
 select id into account from auth.users where lower(email)=lower(trim(teacher_email)) and email_confirmed_at is not null;
 if account is null then raise exception 'Create and confirm the teacher login first'; end if;
 insert into public.teacher_assignments(user_id,campus_id,class_name,academic_year,starts_on,ends_on)
 values(account,target_campus,trim(target_class),trim(target_year),year_start,year_end);
end $$;
create function public.assign_teacher(teacher_email text, target_campus uuid, target_class text, target_year text, year_start date, year_end date) returns void
language sql security invoker set search_path='' as $$ select private.assign_teacher(teacher_email,target_campus,target_class,target_year,year_start,year_end); $$;
revoke all on function private.assign_teacher(text,uuid,text,text,date,date),public.assign_teacher(text,uuid,text,text,date,date) from public,anon,authenticated;
grant execute on function private.assign_teacher(text,uuid,text,text,date,date),public.assign_teacher(text,uuid,text,text,date,date) to authenticated;
create or replace function public.import_school_rows(kind text, rows jsonb) returns jsonb
language plpgsql security invoker set search_path='' as $$
declare r jsonb; campus uuid; student uuid; contact uuid; n int:=0; linked int:=0;
begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 if rows is null or jsonb_typeof(rows) <> 'array' or jsonb_array_length(rows) not between 1 and 500 then raise exception 'Upload 1 to 500 rows per batch'; end if;
 if kind is null or kind not in ('campuses','students','parents') then raise exception 'Unknown import type'; end if;
 for r in select value from jsonb_array_elements(rows) loop
  n:=n+1;
  begin
   if kind='campuses' then
    insert into public.campuses(code,name) values(trim(r->>'campus_code'),trim(r->>'campus_name'));
   else
    select id into campus from public.campuses where code=trim(r->>'campus_code');
    if campus is null then raise exception 'Campus not found or not accessible'; end if;
    if kind='students' then
     insert into public.students(campus_id,admission_number,full_name,class_name,status) values(campus,trim(r->>'admission_number'),trim(r->>'student_name'),trim(r->>'class_name'),coalesce(nullif(lower(trim(r->>'status')),''),'active'));
    else
     select id into student from public.students where campus_id=campus and admission_number=trim(r->>'admission_number');
     if student is null then raise exception 'Student not found or not accessible'; end if;
     insert into public.parent_contacts(campus_id,student_id,full_name,email,phone) values(campus,student,trim(r->>'parent_name'),lower(trim(r->>'parent_email')),coalesce(trim(r->>'phone'),'')) returning id into contact;
     if public.link_registered_parent(contact) then linked:=linked+1; end if;
    end if;
   end if;
  exception when others then raise exception 'Row %: %',n,sqlerrm; end;
 end loop;
 return jsonb_build_object('imported',n,'linked',linked,'pending',case when kind='parents' then n-linked else 0 end);
end $$;
commit;
