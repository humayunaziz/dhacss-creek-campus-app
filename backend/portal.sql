-- Additive portal schema. Apply after schema.sql; existing mobile data is preserved.
begin;
alter table public.students add constraint students_id_campus_unique unique(id, campus_id);
create table public.parent_contacts (
 id uuid primary key default gen_random_uuid(),
 campus_id uuid not null references public.campuses(id),
 student_id uuid not null,
 full_name text not null check(length(trim(full_name)) between 1 and 120),
 email text not null check(email = lower(trim(email)) and email ~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$'),
 phone text not null default '' check(length(phone) <= 40),
 created_at timestamptz not null default now(),
 unique(student_id,email),
 foreign key(student_id,campus_id) references public.students(id,campus_id) on delete cascade
);
create index parent_contacts_campus on public.parent_contacts(campus_id);
create table public.teacher_assignments (
 id uuid primary key default gen_random_uuid(),
 user_id uuid not null references auth.users(id) on delete cascade,
 campus_id uuid not null references public.campuses(id),
 class_name text not null check(length(trim(class_name)) between 1 and 50),
 unique(user_id,campus_id,class_name)
);
create index teacher_assignments_campus on public.teacher_assignments(campus_id);
alter table public.parent_contacts enable row level security;
alter table public.teacher_assignments enable row level security;
revoke all on public.parent_contacts,public.teacher_assignments from public,anon,authenticated;
grant select,insert on public.parent_contacts to authenticated;
grant select,delete on public.teacher_assignments to authenticated;
create policy contacts_read on public.parent_contacts for select to authenticated using(private.can_manage_campus(campus_id));
create policy contacts_insert on public.parent_contacts for insert to authenticated with check(private.can_manage_campus(campus_id));
create policy assignments_read on public.teacher_assignments for select to authenticated using(user_id=(select auth.uid()) or private.can_manage_campus(campus_id));
create policy assignments_delete on public.teacher_assignments for delete to authenticated using(private.can_manage_campus(campus_id));

create function private.can_teach(campus uuid, class_label text) returns boolean
language sql stable security invoker set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.teacher_assignments a
 where a.user_id=auth.uid() and a.campus_id=campus and a.class_name=class_label);
$$;
create function private.can_record_student(target uuid) returns boolean
language sql stable security definer set search_path='' as $$
 select auth.uid() is not null and exists(select 1 from public.students s where s.id=target and
 (private.can_manage_campus(s.campus_id) or exists(select 1 from public.teacher_assignments a
 where a.user_id=auth.uid() and a.campus_id=s.campus_id and a.class_name=s.class_name)));
$$;
revoke all on function private.can_teach(uuid,text),private.can_record_student(uuid) from public,anon,authenticated;
grant execute on function private.can_teach(uuid,text),private.can_record_student(uuid) to authenticated;
create policy teacher_campuses_read on public.campuses for select to authenticated using(exists(select 1 from public.teacher_assignments a where a.campus_id=campuses.id and a.user_id=(select auth.uid())));
create policy teacher_students_read on public.students for select to authenticated using(private.can_teach(campus_id,class_name));

create table public.attendance (
 student_id uuid not null references public.students(id) on delete cascade,
 attendance_date date not null check(attendance_date <= current_date),
 status text not null check(status in ('present','absent','late','excused')),
 recorded_by uuid not null default auth.uid() references auth.users(id),
 updated_at timestamptz not null default now(),
 primary key(student_id,attendance_date)
);
create index attendance_recorded_by on public.attendance(recorded_by);
create table public.homework (
 id uuid primary key default gen_random_uuid(),
 campus_id uuid not null references public.campuses(id),
 class_name text not null check(length(trim(class_name)) between 1 and 50),
 subject text not null check(length(trim(subject)) between 1 and 100),
 title text not null check(length(trim(title)) between 1 and 200),
 instructions text not null check(length(trim(instructions)) between 1 and 10000),
 due_date date not null,
 created_by uuid not null default auth.uid() references auth.users(id),
 created_at timestamptz not null default now()
);
create index homework_campus_class on public.homework(campus_id,class_name);
create index homework_created_by on public.homework(created_by);
alter table public.attendance enable row level security;
alter table public.homework enable row level security;
revoke all on public.attendance,public.homework from public,anon,authenticated;
grant select,insert on public.attendance,public.homework to authenticated;
grant update(status,recorded_by,updated_at) on public.attendance to authenticated;
create policy attendance_read on public.attendance for select to authenticated using(private.can_record_student(student_id) or exists(select 1 from public.parent_student_links l where l.student_id=attendance.student_id and l.parent_id=(select auth.uid())));
create policy attendance_insert on public.attendance for insert to authenticated with check(private.can_record_student(student_id) and recorded_by=(select auth.uid()));
create policy attendance_update on public.attendance for update to authenticated using(private.can_record_student(student_id)) with check(private.can_record_student(student_id) and recorded_by=(select auth.uid()));
create policy homework_read on public.homework for select to authenticated using(private.can_manage_campus(campus_id) or private.can_teach(campus_id,class_name) or exists(select 1 from public.students s join public.parent_student_links l on l.student_id=s.id where s.campus_id=homework.campus_id and s.class_name=homework.class_name and l.parent_id=(select auth.uid())));
create policy homework_insert on public.homework for insert to authenticated with check((private.can_manage_campus(campus_id) or private.can_teach(campus_id,class_name)) and created_by=(select auth.uid()));

-- Narrow privileged operations: never expose auth.users or a privileged key to the browser.
create function private.link_registered_parent(contact_id uuid) returns boolean
language plpgsql security definer set search_path='' as $$
declare c public.parent_contacts; account uuid;
begin
 select * into c from public.parent_contacts where id=contact_id;
 if auth.uid() is null or c.id is null or not private.can_manage_campus(c.campus_id) then raise exception 'Not authorized' using errcode='42501'; end if;
 select id into account from auth.users where lower(email)=c.email and email_confirmed_at is not null;
 if account is null then return false; end if;
 insert into public.parent_student_links(parent_id,student_id) values(account,c.student_id) on conflict do nothing;
 return true;
end $$;
create function private.assign_teacher(teacher_email text, target_campus uuid, target_class text) returns void
language plpgsql security definer set search_path='' as $$
declare account uuid;
begin
 if auth.uid() is null or not private.can_manage_campus(target_campus) then raise exception 'Not authorized' using errcode='42501'; end if;
 select id into account from auth.users where lower(email)=lower(trim(teacher_email)) and email_confirmed_at is not null;
 if account is null then raise exception 'Create and confirm the teacher login first'; end if;
 insert into public.teacher_assignments(user_id,campus_id,class_name) values(account,target_campus,trim(target_class)) on conflict do nothing;
end $$;
create function public.link_registered_parent(contact_id uuid) returns boolean language sql security invoker set search_path='' as $$ select private.link_registered_parent(contact_id); $$;
create function public.assign_teacher(teacher_email text, target_campus uuid, target_class text) returns void language sql security invoker set search_path='' as $$ select private.assign_teacher(teacher_email,target_campus,target_class); $$;
revoke all on function private.link_registered_parent(uuid),private.assign_teacher(text,uuid,text) from public,anon,authenticated;
grant execute on function private.link_registered_parent(uuid),private.assign_teacher(text,uuid,text) to authenticated;
revoke all on function public.link_registered_parent(uuid),public.assign_teacher(text,uuid,text) from public,anon,authenticated;
grant execute on function public.link_registered_parent(uuid),public.assign_teacher(text,uuid,text) to authenticated;

-- Each upload commits atomically. Repeated rows fail instead of overwriting existing records.
create function public.import_school_rows(kind text, rows jsonb) returns jsonb
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
     insert into public.students(campus_id,admission_number,full_name,class_name) values(campus,trim(r->>'admission_number'),trim(r->>'student_name'),trim(r->>'class_name'));
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
revoke all on function public.import_school_rows(text,jsonb) from public,anon,authenticated;
grant execute on function public.import_school_rows(text,jsonb) to authenticated;
create function public.record_attendance(day date, entries jsonb) returns integer
language plpgsql security invoker set search_path='' as $$
declare r jsonb; n integer:=0;
begin
 if auth.uid() is null then raise exception 'Sign in required' using errcode='42501'; end if;
 if day is null or day>current_date then raise exception 'Choose today or an earlier date'; end if;
 if entries is null or jsonb_typeof(entries)<>'array' or jsonb_array_length(entries) not between 1 and 500 then raise exception 'Save 1 to 500 attendance records'; end if;
 for r in select value from jsonb_array_elements(entries) loop
  insert into public.attendance(student_id,attendance_date,status,recorded_by,updated_at)
  values((r->>'student_id')::uuid,day,r->>'status',auth.uid(),now())
  on conflict(student_id,attendance_date) do update set status=excluded.status,recorded_by=excluded.recorded_by,updated_at=excluded.updated_at;
  n:=n+1;
 end loop;
 return n;
end $$;
revoke all on function public.record_attendance(date,jsonb) from public,anon,authenticated;
grant execute on function public.record_attendance(date,jsonb) to authenticated;
commit;
