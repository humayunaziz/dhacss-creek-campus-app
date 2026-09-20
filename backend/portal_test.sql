-- Transaction-only fixtures. No real accounts, emails, or school records are changed.
begin;
insert into auth.users(id,email,email_confirmed_at) values
('90000000-0000-0000-0000-000000000001','portal-head@example.test',now()),
('90000000-0000-0000-0000-000000000002','portal-admin@example.test',now()),
('90000000-0000-0000-0000-000000000003','portal-teacher@example.test',now()),
('90000000-0000-0000-0000-000000000004','portal-parent@example.test',now()),
('90000000-0000-0000-0000-000000000005','portal-unconfirmed@example.test',null);
insert into public.campuses(id,code,name) values
('91000000-0000-0000-0000-000000000001','__PORTAL_A__','Portal A'),
('91000000-0000-0000-0000-000000000002','__PORTAL_B__','Portal B');
insert into public.staff_memberships(user_id,campus_id,role) values
('90000000-0000-0000-0000-000000000001',null,'head_office'),
('90000000-0000-0000-0000-000000000002','91000000-0000-0000-0000-000000000001','campus_admin');
insert into public.students(id,campus_id,admission_number,full_name,class_name) values
('92000000-0000-0000-0000-000000000001','91000000-0000-0000-0000-000000000001','P1','Portal Child A','One'),
('92000000-0000-0000-0000-000000000002','91000000-0000-0000-0000-000000000001','P2','Portal Child B','Two'),
('92000000-0000-0000-0000-000000000003','91000000-0000-0000-0000-000000000002','P3','Portal Child C','One');
set local role authenticated;
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000002',true);
do $$ declare result jsonb; contact uuid; begin
 perform public.assign_teacher('portal-teacher@example.test','91000000-0000-0000-0000-000000000001','One');
 begin
  perform public.assign_teacher('portal-teacher@example.test','91000000-0000-0000-0000-000000000002','One');
  raise exception 'FAIL cross campus teacher assignment';
 exception when insufficient_privilege then null; end;
 result:=public.import_school_rows('parents','[{"campus_code":"__PORTAL_A__","admission_number":"P1","parent_name":"Parent","parent_email":"portal-parent@example.test","phone":"00123"},{"campus_code":"__PORTAL_A__","admission_number":"P2","parent_name":"Pending","parent_email":"portal-unconfirmed@example.test","phone":""}]');
 if (result->>'linked')::int<>1 or (result->>'pending')::int<>1 then raise exception 'FAIL confirmed parent matching'; end if;
 if exists(select 1 from public.parent_student_links where parent_id='90000000-0000-0000-0000-000000000005') then raise exception 'FAIL unconfirmed parent linked'; end if;
 -- First row is valid, second is duplicate. The entire function call must roll back.
 begin
  perform public.import_school_rows('students','[{"campus_code":"__PORTAL_A__","admission_number":"NEW","student_name":"Rollback","class_name":"One"},{"campus_code":"__PORTAL_A__","admission_number":"P1","student_name":"Duplicate","class_name":"One"}]');
  raise exception 'IMPORT_UNEXPECTEDLY_SUCCEEDED';
 exception when others then if sqlerrm='IMPORT_UNEXPECTEDLY_SUCCEEDED' then raise; end if; end;
 if exists(select 1 from public.students where campus_id='91000000-0000-0000-0000-000000000001' and admission_number='NEW') then raise exception 'FAIL non-atomic import'; end if;
 begin
  perform public.import_school_rows('students','[{"campus_code":"__PORTAL_B__","admission_number":"ILLEGAL","student_name":"Cross campus","class_name":"One"}]');
  raise exception 'IMPORT_UNEXPECTEDLY_SUCCEEDED';
 exception when others then if sqlerrm='IMPORT_UNEXPECTEDLY_SUCCEEDED' then raise; end if; end;
end $$;
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000003',true);
do $$ declare n integer; begin
 if not exists(select 1 from public.students where id='92000000-0000-0000-0000-000000000001') then raise exception 'FAIL teacher roster missing'; end if;
 if exists(select 1 from public.students where id in ('92000000-0000-0000-0000-000000000002','92000000-0000-0000-0000-000000000003')) then raise exception 'FAIL teacher sees other class'; end if;
 if exists(select 1 from public.parent_contacts where campus_id='91000000-0000-0000-0000-000000000001') then raise exception 'FAIL teacher sees parent contacts'; end if;
 perform public.record_attendance(current_date,'[{"student_id":"92000000-0000-0000-0000-000000000001","status":"present"}]');
 perform public.record_attendance(current_date,'[{"student_id":"92000000-0000-0000-0000-000000000001","status":"late"}]');
 if not exists(select 1 from public.attendance where student_id='92000000-0000-0000-0000-000000000001' and status='late') then raise exception 'FAIL attendance correction'; end if;
 begin
  perform public.record_attendance(current_date,'[{"student_id":"92000000-0000-0000-0000-000000000001","status":"absent"},{"student_id":"92000000-0000-0000-0000-000000000002","status":"present"}]');
  raise exception 'FAIL cross class attendance';
 exception when insufficient_privilege then null; end;
 if not exists(select 1 from public.attendance where student_id='92000000-0000-0000-0000-000000000001' and status='late') then raise exception 'FAIL non-atomic attendance'; end if;
 insert into public.homework(campus_id,class_name,subject,title,instructions,due_date) values('91000000-0000-0000-0000-000000000001','One','Math','Portal test','Complete task',current_date+1);
 begin
  insert into public.homework(campus_id,class_name,subject,title,instructions,due_date) values('91000000-0000-0000-0000-000000000001','Two','Math','Illegal','Task',current_date+1);
  raise exception 'FAIL cross class homework';
 exception when insufficient_privilege then null; end;
 begin
  perform public.assign_teacher('portal-teacher@example.test','91000000-0000-0000-0000-000000000001','Two');
  raise exception 'FAIL teacher self escalation';
 exception when insufficient_privilege then null; end;
 update public.students set full_name='Attack' where id='92000000-0000-0000-0000-000000000001';get diagnostics n=row_count;
 if n<>0 then raise exception 'FAIL teacher edits students'; end if;
end $$;
select set_config('request.jwt.claim.sub','90000000-0000-0000-0000-000000000004',true);
do $$ begin
 if not exists(select 1 from public.attendance where student_id='92000000-0000-0000-0000-000000000001') then raise exception 'FAIL parent attendance read'; end if;
 if not exists(select 1 from public.homework where campus_id='91000000-0000-0000-0000-000000000001' and class_name='One') then raise exception 'FAIL parent homework read'; end if;
 begin
  perform public.record_attendance(current_date,'[{"student_id":"92000000-0000-0000-0000-000000000001","status":"absent"}]');
  raise exception 'FAIL parent writes attendance';
 exception when insufficient_privilege then null; end;
end $$;
reset role;
set local role anon;
do $$ begin
 begin perform public.import_school_rows('campuses','[]'); raise exception 'FAIL anonymous import'; exception when insufficient_privilege then null; end;
 begin perform * from public.homework; raise exception 'FAIL anonymous homework'; exception when insufficient_privilege then null; end;
end $$;
reset role;
rollback;
select 'PASS: atomic imports, confirmed parent linking, teacher class isolation, attendance and homework access' as result;
