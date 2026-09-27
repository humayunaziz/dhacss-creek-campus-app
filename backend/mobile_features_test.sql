begin;
insert into auth.users(id,email,email_confirmed_at) values
 ('b1000000-0000-0000-0000-000000000001','mobile-admin@example.test',now()),
 ('b1000000-0000-0000-0000-000000000002','mobile-parent@example.test',now()),
 ('b1000000-0000-0000-0000-000000000003','mobile-student@example.test',now()),
 ('b1000000-0000-0000-0000-000000000004','mobile-other@example.test',now()),
 ('b1000000-0000-0000-0000-000000000005','mobile-teacher@example.test',now());
insert into public.campuses(id,code,name) values
 ('b2000000-0000-0000-0000-000000000001','__MOBILE_TEST__','Mobile test'),
 ('b2000000-0000-0000-0000-000000000002','__MOBILE_OTHER__','Other campus');
insert into public.staff_memberships(user_id,campus_id,role) values('b1000000-0000-0000-0000-000000000001','b2000000-0000-0000-0000-000000000001','campus_admin');
insert into public.students(id,campus_id,full_name,admission_number,class_name) values
 ('b3000000-0000-0000-0000-000000000001','b2000000-0000-0000-0000-000000000001','Mobile Child','MOB1','One'),
 ('b3000000-0000-0000-0000-000000000002','b2000000-0000-0000-0000-000000000001','Other Class','MOB2','Two');
insert into public.parent_student_links values('b1000000-0000-0000-0000-000000000002','b3000000-0000-0000-0000-000000000001',now());
insert into public.student_accounts values('b1000000-0000-0000-0000-000000000003','b3000000-0000-0000-0000-000000000001');
insert into public.teacher_assignments(user_id,campus_id,class_name,academic_year,starts_on,ends_on) values('b1000000-0000-0000-0000-000000000005','b2000000-0000-0000-0000-000000000001','One','Test year',current_date-1,current_date+1);
set local role authenticated;
select set_config('request.jwt.claim.sub','b1000000-0000-0000-0000-000000000001',true);
insert into public.school_publications(campus_id,class_name,kind,title,body) values
 ('b2000000-0000-0000-0000-000000000001',null,'notice','Campus notice','Everyone in campus'),
 ('b2000000-0000-0000-0000-000000000001','One','timetable','Class one','Schedule'),
 ('b2000000-0000-0000-0000-000000000001','Two','notice','Class two','Other class only');
do $$begin
 begin insert into public.school_publications(campus_id,kind,title,body) values('b2000000-0000-0000-0000-000000000002','notice','Forbidden','Cross campus');raise exception 'FAIL campus write';exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claim.sub','b1000000-0000-0000-0000-000000000002',true);
insert into public.leave_requests(id,student_id,starts_on,ends_on,reason) values('b4000000-0000-0000-0000-000000000001','b3000000-0000-0000-0000-000000000001',current_date+2,current_date+3,'Family event');
insert into public.school_messages(student_id,body) values('b3000000-0000-0000-0000-000000000001','Hello school');
do $$begin
 if (select count(*) from public.school_publications)<>2 then raise exception 'FAIL parent publication scope';end if;
 begin insert into public.school_messages(student_id,sender_id,body) values('b3000000-0000-0000-0000-000000000001','b1000000-0000-0000-0000-000000000001','Spoof sender');raise exception 'FAIL sender spoof';exception when insufficient_privilege then null;end;
 begin insert into public.school_messages(student_id,body) values('b3000000-0000-0000-0000-000000000002','Forbidden');raise exception 'FAIL parent cross-child message';exception when insufficient_privilege then null;end;
 begin insert into public.leave_requests(student_id,starts_on,ends_on,reason,status) values('b3000000-0000-0000-0000-000000000001',current_date+2,current_date+3,'Spoof approved','approved');raise exception 'FAIL spoof decision';exception when insufficient_privilege then null;end;
 begin perform public.review_school_leave('b4000000-0000-0000-0000-000000000001','approved','');raise exception 'FAIL self approve';exception when insufficient_privilege then null;end;
end $$;
select set_config('request.jwt.claim.sub','b1000000-0000-0000-0000-000000000005',true);
insert into public.student_results(student_id,exam_name,subject,exam_date,marks,total) values('b3000000-0000-0000-0000-000000000001','Term 1','Math',current_date,80,100);
select public.review_school_leave('b4000000-0000-0000-0000-000000000001','approved','Approved by class teacher');
do $$begin
 begin insert into public.student_results(student_id,exam_name,subject,exam_date,marks,total) values('b3000000-0000-0000-0000-000000000002','Term 1','Math',current_date,80,100);raise exception 'FAIL teacher other class';exception when insufficient_privilege then null;end;
 begin perform public.review_school_leave('b4000000-0000-0000-0000-000000000001','rejected','Changed mind');raise exception 'FAIL reviewed twice';exception when raise_exception then if SQLERRM not like 'Only pending%' then raise;end if;end;
end $$;
select set_config('request.jwt.claim.sub','b1000000-0000-0000-0000-000000000003',true);
do $$begin
 if (select count(*) from public.students)<>1 or (select count(*) from public.school_publications)<>2 or (select count(*) from public.student_results)<>1 or (select count(*) from public.school_messages)<>1 then raise exception 'FAIL student account scope';end if;
end $$;
select set_config('request.jwt.claim.sub','b1000000-0000-0000-0000-000000000004',true);
do $$begin
 if exists(select 1 from public.school_publications) or exists(select 1 from public.school_messages) or exists(select 1 from public.leave_requests) or exists(select 1 from public.student_results) then raise exception 'FAIL unrelated account visibility';end if;
end $$;
reset role;
rollback;
select 'PASS: class/campus publications, student login, results, family messages, leave submit/review, no self-approval or sender spoofing, no cross-child/campus access; fixtures rolled back.' as result;
