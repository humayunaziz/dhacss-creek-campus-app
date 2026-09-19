-- Initial schema. Apply once to an empty Supabase project using apply_migration.
begin;
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create table public.campuses (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 120),
  code text not null unique check (length(trim(code)) between 1 and 30),
  created_at timestamptz not null default now()
);
create table public.staff_memberships (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  campus_id uuid references public.campuses(id) on delete cascade,
  role text not null check (role in ('head_office', 'campus_admin')),
  check ((role = 'head_office' and campus_id is null) or
         (role = 'campus_admin' and campus_id is not null))
);
create unique index staff_memberships_campus_unique on public.staff_memberships(user_id, campus_id) where campus_id is not null;
create unique index staff_memberships_head_unique on public.staff_memberships(user_id) where role = 'head_office';
create index staff_memberships_campus_idx on public.staff_memberships(campus_id);
create table public.students (
  id uuid primary key default gen_random_uuid(),
  campus_id uuid not null references public.campuses(id),
  full_name text not null check (length(trim(full_name)) between 1 and 120),
  admission_number text not null check (length(trim(admission_number)) between 1 and 50),
  class_name text not null check (length(trim(class_name)) between 1 and 50),
  created_at timestamptz not null default now(),
  unique(campus_id, admission_number)
);
create table public.parent_student_links (
  parent_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key(parent_id, student_id)
);
create index parent_student_links_student_idx on public.parent_student_links(student_id);

alter table public.campuses enable row level security;
alter table public.staff_memberships enable row level security;
alter table public.students enable row level security;
alter table public.parent_student_links enable row level security;
revoke all on public.campuses, public.staff_memberships, public.students, public.parent_student_links from public, anon, authenticated;
grant select on public.campuses, public.staff_memberships, public.students, public.parent_student_links to authenticated;
grant insert, delete on public.campuses, public.students, public.parent_student_links to authenticated;
grant update(name, code) on public.campuses to authenticated;
-- Campus and identity cannot be changed through the client, preserving link scope.
grant update(full_name, admission_number, class_name) on public.students to authenticated;

create policy staff_read_self on public.staff_memberships for select to authenticated
  using (user_id = (select auth.uid()));
-- Membership assignment is deliberately server/dashboard only: clients cannot promote themselves.
create function private.is_head_office() returns boolean
language sql stable security invoker set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.staff_memberships where user_id = auth.uid() and role = 'head_office'
  );
$$;
create function private.can_manage_campus(target uuid) returns boolean
language sql stable security invoker set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.staff_memberships where user_id = auth.uid()
      and (role = 'head_office' or (role = 'campus_admin' and campus_id = target))
  );
$$;
-- Narrow internal lookup avoids circular student/link RLS. No user-supplied actor ID.
-- Keep private schema out of the exposed API schemas.
create function private.can_manage_student(target uuid) returns boolean
language sql stable security definer set search_path = '' as $$
  select auth.uid() is not null and exists (
    select 1 from public.students s join public.staff_memberships m
      on m.user_id = auth.uid() and (m.role = 'head_office' or m.campus_id = s.campus_id)
    where s.id = target
  );
$$;
revoke all on function private.is_head_office(), private.can_manage_campus(uuid), private.can_manage_student(uuid) from public, anon, authenticated;
grant execute on function private.is_head_office(), private.can_manage_campus(uuid), private.can_manage_student(uuid) to authenticated;

create policy links_read on public.parent_student_links for select to authenticated
  using (parent_id = (select auth.uid()) or private.can_manage_student(student_id));
create policy links_insert on public.parent_student_links for insert to authenticated
  with check (private.can_manage_student(student_id));
create policy links_delete on public.parent_student_links for delete to authenticated
  using (private.can_manage_student(student_id));

create policy students_read on public.students for select to authenticated
  using (private.can_manage_campus(campus_id) or exists (
    select 1 from public.parent_student_links l where l.student_id = students.id and l.parent_id = (select auth.uid())
  ));
create policy students_insert on public.students for insert to authenticated
  with check (private.can_manage_campus(campus_id));
create policy students_update on public.students for update to authenticated
  using (private.can_manage_campus(campus_id)) with check (private.can_manage_campus(campus_id));
create policy students_delete on public.students for delete to authenticated
  using (private.can_manage_campus(campus_id));

create policy campuses_read on public.campuses for select to authenticated
  using (private.can_manage_campus(id) or exists (
    select 1 from public.students s join public.parent_student_links l on l.student_id = s.id
    where s.campus_id = campuses.id and l.parent_id = (select auth.uid())
  ));
create policy campuses_insert on public.campuses for insert to authenticated
  with check ((select private.is_head_office()));
create policy campuses_update on public.campuses for update to authenticated
  using ((select private.is_head_office())) with check ((select private.is_head_office()));
create policy campuses_delete on public.campuses for delete to authenticated
  using ((select private.is_head_office()));
commit;
