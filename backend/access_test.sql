-- Exercise real Postgres grants/RLS, not mocked policy predicates. Roll back fixtures.
begin;
insert into auth.users(id) values
 ('00000000-0000-0000-0000-000000000001'), -- parent A
 ('00000000-0000-0000-0000-000000000002'), -- parent B
 ('00000000-0000-0000-0000-000000000003'), -- campus A admin
 ('00000000-0000-0000-0000-000000000004'), -- head office
 ('00000000-0000-0000-0000-000000000005'); -- unlinked
insert into public.campuses(id,name,code) values
 ('10000000-0000-0000-0000-000000000001','Campus A','A'),
 ('10000000-0000-0000-0000-000000000002','Campus B','B');
insert into public.students(id,campus_id,full_name,admission_number,class_name) values
 ('20000000-0000-0000-0000-000000000001','10000000-0000-0000-0000-000000000001','Child A','A1','One'),
 ('20000000-0000-0000-0000-000000000002','10000000-0000-0000-0000-000000000002','Child B','B1','Two');
insert into public.parent_student_links(parent_id,student_id) values
 ('00000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000001'),
 ('00000000-0000-0000-0000-000000000002','20000000-0000-0000-0000-000000000002');
insert into public.staff_memberships(user_id,campus_id,role) values
 ('00000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','campus_admin'),
 ('00000000-0000-0000-0000-000000000004',null,'head_office');

set local role anon;
do $$ begin
  begin perform * from public.students; raise exception 'FAIL anonymous read'; exception when insufficient_privilege then null; end;
  begin insert into public.campuses(name,code) values ('Attack','X'); raise exception 'FAIL anonymous write'; exception when insufficient_privilege then null; end;
end $$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000001',true);
do $$ declare n integer; begin
  if (select count(*) from public.students) <> 1 or not exists(select 1 from public.students where full_name='Child A') then raise exception 'FAIL parent child isolation'; end if;
  if (select count(*) from public.campuses) <> 1 then raise exception 'FAIL parent campus isolation'; end if;
  if (select count(*) from public.parent_student_links) <> 1 then raise exception 'FAIL parent link isolation'; end if;
  if exists(select 1 from public.staff_memberships) then raise exception 'FAIL staff data leak'; end if;
  begin insert into public.staff_memberships(user_id,role) values (auth.uid(),'head_office'); raise exception 'FAIL self promotion'; exception when insufficient_privilege then null; end;
  begin insert into public.parent_student_links(parent_id,student_id) values (auth.uid(),'20000000-0000-0000-0000-000000000002'); raise exception 'FAIL self link'; exception when insufficient_privilege then null; end;
  begin insert into public.students(campus_id,full_name,admission_number,class_name) values ('10000000-0000-0000-0000-000000000001','Attack','XX','One'); raise exception 'FAIL parent insert'; exception when insufficient_privilege then null; end;
  update public.students set full_name='Attack'; get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL parent update'; end if;
  delete from public.parent_student_links; get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL parent unlink'; end if;
  delete from public.students; get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL parent delete'; end if;
end $$;

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000002',true);
do $$ begin
  if (select count(*) from public.students) <> 1 or not exists(select 1 from public.students where full_name='Child B') then raise exception 'FAIL second parent isolation'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000005',true);
do $$ begin
  if exists(select 1 from public.students) or exists(select 1 from public.campuses) or exists(select 1 from public.parent_student_links) then raise exception 'FAIL unlinked user visibility'; end if;
end $$;

select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
do $$ declare n integer; begin
  if (select count(*) from public.students) <> 1 or (select count(*) from public.campuses) <> 1 then raise exception 'FAIL admin isolation'; end if;
  if (select count(*) from public.staff_memberships) <> 1 then raise exception 'FAIL own membership read'; end if;
  begin insert into public.campuses(name,code) values ('Attack','X'); raise exception 'FAIL admin campus create'; exception when insufficient_privilege then null; end;
  begin insert into public.students(campus_id,full_name,admission_number,class_name) values ('10000000-0000-0000-0000-000000000002','Attack','XX','One'); raise exception 'FAIL cross campus insert'; exception when insufficient_privilege then null; end;
  begin insert into public.parent_student_links(parent_id,student_id) values ('00000000-0000-0000-0000-000000000001','20000000-0000-0000-0000-000000000002'); raise exception 'FAIL cross campus link'; exception when insufficient_privilege then null; end;
  begin update public.students set campus_id='10000000-0000-0000-0000-000000000002'; raise exception 'FAIL campus transfer'; exception when insufficient_privilege then null; end;
  begin update public.staff_memberships set role='head_office',campus_id=null; raise exception 'FAIL admin self promotion'; exception when insufficient_privilege then null; end;
  update public.students set full_name='Allowed' where id='20000000-0000-0000-0000-000000000001'; get diagnostics n = row_count;
  if n <> 1 then raise exception 'FAIL allowed update'; end if;
  update public.students set full_name='Attack' where id='20000000-0000-0000-0000-000000000002'; get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL cross campus update'; end if;
  delete from public.students where id='20000000-0000-0000-0000-000000000002'; get diagnostics n = row_count;
  if n <> 0 then raise exception 'FAIL cross campus delete'; end if;
  insert into public.students(id,campus_id,full_name,admission_number,class_name) values ('20000000-0000-0000-0000-000000000003','10000000-0000-0000-0000-000000000001','New child','A2','One');
  insert into public.parent_student_links(parent_id,student_id) values ('00000000-0000-0000-0000-000000000005','20000000-0000-0000-0000-000000000003');
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000005',true);
do $$ begin
  if (select count(*) from public.students) <> 1 then raise exception 'FAIL new parent link visibility'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000003',true);
delete from public.parent_student_links where student_id='20000000-0000-0000-0000-000000000003';
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000005',true);
do $$ begin
  if exists(select 1 from public.students) then raise exception 'FAIL immediate unlink revocation'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000000004',true);
do $$ begin
  if (select count(*) from public.campuses) <> 2 or (select count(*) from public.students) <> 3 then raise exception 'FAIL head office read'; end if;
  insert into public.campuses(name,code) values ('New Campus','NEW');
  update public.campuses set name='Renamed' where code='NEW';
  if not exists(select 1 from public.campuses where name='Renamed') then raise exception 'FAIL head office update'; end if;
  delete from public.campuses where code='NEW';
end $$;
reset role;
rollback;
select 'PASS: anonymous, parent, unlinked user, campus admin and head office access controls' as result;
