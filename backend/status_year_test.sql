begin;
insert into auth.users(id,email,email_confirmed_at) values
 ('93000000-0000-0000-0000-000000000001','year-head@example.test',now()),
 ('93000000-0000-0000-0000-000000000002','year-teacher@example.test',now());
insert into public.campuses(id,code,name) values('94000000-0000-0000-0000-000000000001','__YEAR_TEST__','Year Test');
insert into public.staff_memberships(user_id,role) values('93000000-0000-0000-0000-000000000001','head_office');
insert into public.students(id,campus_id,full_name,admission_number,class_name) values('95000000-0000-0000-0000-000000000001','94000000-0000-0000-0000-000000000001','Year Child','TEST','One');
set local role authenticated;
select set_config('request.jwt.claim.sub','93000000-0000-0000-0000-000000000001',true);
do $$ declare st text; begin
 foreach st in array array['active','transferred','suspended','inactive','left'] loop
  update public.students set status=st where id='95000000-0000-0000-0000-000000000001';
  if not exists(select 1 from public.students where id='95000000-0000-0000-0000-000000000001' and status=st) then raise exception 'FAIL status update'; end if;
 end loop;
 begin update public.students set status='invalid' where id='95000000-0000-0000-0000-000000000001';raise exception 'FAIL invalid status accepted'; exception when check_violation then null;end;
 perform public.assign_teacher('year-teacher@example.test','94000000-0000-0000-0000-000000000001','One','Current',current_date-5,current_date+5);
 perform public.assign_teacher('year-teacher@example.test','94000000-0000-0000-0000-000000000001','One','Next',current_date+6,current_date+370);
 begin
 perform public.assign_teacher('year-teacher@example.test','94000000-0000-0000-0000-000000000001','One','Current',current_date-5,current_date+5);
 raise exception 'FAIL duplicate assignment';exception when unique_violation then null;end;
end $$;
select set_config('request.jwt.claim.sub','93000000-0000-0000-0000-000000000002',true);
do $$ declare n int; begin
 if not exists(select 1 from public.students where id='95000000-0000-0000-0000-000000000001') then raise exception 'FAIL current roster missing';end if;
 update public.students set status='active' where id='95000000-0000-0000-0000-000000000001';get diagnostics n=row_count;if n<>0 then raise exception 'FAIL teacher status edit';end if;
 perform public.record_attendance(current_date,'[{"student_id":"95000000-0000-0000-0000-000000000001","status":"present"}]');
 begin perform public.record_attendance(current_date-10,'[{"student_id":"95000000-0000-0000-0000-000000000001","status":"present"}]');raise exception 'FAIL attendance outside year';exception when insufficient_privilege then null;end;
end $$;
reset role;
update public.teacher_assignments set starts_on=current_date-370,ends_on=current_date-1 where user_id='93000000-0000-0000-0000-000000000002' and academic_year='Current';
set local role authenticated;
do $$ begin
 if exists(select 1 from public.students where id='95000000-0000-0000-0000-000000000001') then raise exception 'FAIL expired/future assignment grants roster';end if;
 begin perform public.record_attendance(current_date,'[{"student_id":"95000000-0000-0000-0000-000000000001","status":"absent"}]');raise exception 'FAIL expired attendance write';exception when insufficient_privilege then null;end;
 begin insert into public.homework(campus_id,class_name,subject,title,instructions,due_date) values('94000000-0000-0000-0000-000000000001','One','Math','Expired','Task',current_date);raise exception 'FAIL expired homework write';exception when insufficient_privilege then null;end;
end $$;
reset role;
rollback;
select 'PASS: five statuses, invalid status rejected, teacher cannot edit status, year uniqueness, attendance dates and assignment expiration' as result;
