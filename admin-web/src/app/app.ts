import { Component, inject, signal, OnInit } from '@angular/core';
import { MonthlyFees } from './fees';
import { FormsModule } from '@angular/forms';
import { SchoolData, Row } from './data';
import { columns, ImportKind, ImportRow, parseCsv, validateImport } from './import';

@Component({selector:'app-root',standalone:true,imports:[FormsModule,MonthlyFees],templateUrl:'./app.html'})
export class App implements OnInit {
 readonly db=inject(SchoolData); readonly user=signal<string|null>(null); readonly ready=signal(false);
 readonly busy=signal(false); readonly message=signal(''); readonly error=signal('');
 readonly campuses=signal<Row[]>([]); readonly students=signal<Row[]>([]); readonly memberships=signal<Row[]>([]);
 readonly parents=signal<Row[]>([]); readonly assignments=signal<Row[]>([]); readonly homework=signal<Row[]>([]);
 email='';password='';page='overview'; search=''; campus=''; className=''; teacherEmail='';
 importKind:ImportKind='students'; readonly preview=signal<ImportRow[]>([]); readonly problems=signal<string[]>([]); filename=''; approved=false;
 readonly uploadBusy=signal(false); private fileVersion=0; private sessionVersion=0;
 attendanceDay=new Date().toLocaleDateString('en-CA',{timeZone:'Asia/Karachi'}); readonly marks=signal<Record<string,string>>({});
 subject='';title='';instructions='';due='';
 readonly cols=columns;
 readonly studentStatuses=['active','transferred','suspended','inactive','left'];
 statusFilter=''; academicYear=''; yearStart=''; yearEnd='';
 assignmentCurrent(a:Row){const today=new Date().toLocaleDateString('en-CA',{timeZone:'Asia/Karachi'});return a['starts_on']<=today&&a['ends_on']>=today;}
 async changeStudentStatus(student:Row,status:string){await this.act(async()=>{const {data,error}=await this.db.client.from('students').update({status}).eq('id',student['id']).select('id,status').single();if(error)throw error;this.students.update(rows=>rows.map(s=>s['id']===data.id?{...s,status:data.status}:s));this.message.set('Student status updated.');});}

 async ngOnInit(){
  const {data}=await this.db.client.auth.getSession();
  await this.session(data.session?.user.email??null);
  this.db.client.auth.onAuthStateChange((_event,session)=>{
   const email=session?.user.email??null;
   if(email!==this.user())setTimeout(()=>void this.session(email),0);
  });
 }
 async session(email:string|null){
  this.sessionVersion++;this.user.set(email);this.clear();
  if(email)await this.load();this.ready.set(true);
 }
 clear(){this.campuses.set([]);this.students.set([]);this.memberships.set([]);this.parents.set([]);this.assignments.set([]);this.homework.set([]);this.preview.set([]);this.marks.set({});this.page='overview';this.campus='';this.className='';this.error.set('');this.message.set('');}
 isAdmin(){return this.memberships().length>0;}
 isHead(){return this.memberships().some(r=>r['role']==='head_office');}
 hasAccess(){return this.isAdmin()||this.assignments().some(a=>this.assignmentCurrent(a));}
 async act(work:()=>Promise<void>){
  if(this.busy())return;this.busy.set(true);this.error.set('');this.message.set('');
  try{await work();}catch(e){this.error.set(e instanceof Error?e.message:(e as {message?:string})?.message??'The request failed. Please try again.');}finally{this.busy.set(false);}
 }
 async login(){await this.act(async()=>{const {error}=await this.db.client.auth.signInWithPassword({email:this.email.trim(),password:this.password});this.password='';if(error)throw Error('Could not sign in. Check your email and password.');});}
 async logout(){await this.act(async()=>{const {error}=await this.db.client.auth.signOut();if(error)throw error;await this.session(null);});}
 async load(){const version=this.sessionVersion;await this.act(async()=>{
  const [campuses,students,memberships,parents,assignments,homework]=await Promise.all(['campuses','students','staff_memberships','parent_contacts','teacher_assignments','homework'].map(t=>this.db.all(t)));
  if(version!==this.sessionVersion)return;
  this.campuses.set(campuses);this.students.set(students);this.memberships.set(memberships);this.parents.set(parents);this.assignments.set(assignments);this.homework.set(homework);
 });}
 go(page:string){this.page=page;this.message.set('');this.error.set('');}
 campusName(id:string){return this.campuses().find(c=>c['id']===id)?.['name']??'Campus';}
 studentName(id:string){return this.students().find(s=>s['id']===id)?.['full_name']??'Student';}
 filteredStudents(){const q=this.search.toLowerCase();return this.students().filter(s=>(!this.campus||s['campus_id']===this.campus)&&(!this.statusFilter||s['status']===this.statusFilter)&&(!q||`${s['full_name']} ${s['admission_number']} ${s['class_name']}`.toLowerCase().includes(q)));}
 classes(){return [...new Set([...this.students().filter(s=>s['campus_id']===this.campus).map(s=>String(s['class_name'])),...this.assignments().filter(a=>a['campus_id']===this.campus).map(a=>String(a['class_name']))])].sort();}
 roster(){return this.students().filter(s=>s['campus_id']===this.campus&&s['class_name']===this.className);}
 changeCampus(){this.className='';this.marks.set({});}
 resetImport(){this.fileVersion++;this.preview.set([]);this.problems.set([]);this.filename='';this.approved=false;}
 async chooseFile(event:Event){
  const input=event.target as HTMLInputElement;const file=input.files?.[0];input.value='';this.resetImport();if(!file)return;
  const version=this.fileVersion;const kind=this.importKind;this.filename=file.name;this.uploadBusy.set(true);
  try{
   if(file.size>5*1024*1024)throw Error('Use a file smaller than 5 MB.');
   let grid:string[][];
   if(file.name.toLowerCase().endsWith('.csv'))grid=parseCsv(await file.text());
   else if(file.name.toLowerCase().endsWith('.xlsx')){
    const {Workbook}=await import('exceljs');const workbook=new Workbook();await workbook.xlsx.load(await file.arrayBuffer());
    if(workbook.worksheets.length!==1)throw Error('Use one worksheet per upload.');
    const sheet=workbook.worksheets[0];if(sheet.rowCount>501)throw Error('Use at most 500 data rows.');
    grid=[];sheet.eachRow(row=>{const values:string[]=[];for(let n=1;n<=Math.max(sheet.columnCount,columns[kind].length);n++){
     const cell=row.getCell(n);if(cell.formula)throw Error('Formulas are not allowed. Paste values as text first.');values.push(cell.text);
    }if(values.some(v=>v.trim()))grid.push(values);});
   }else throw Error('Choose a .csv or .xlsx file.');
   if(version!==this.fileVersion)return;
   const result=validateImport(kind,grid);this.preview.set(result.rows);this.problems.set(result.errors);
  }catch(e){if(version===this.fileVersion)this.problems.set([e instanceof Error?e.message:'Could not read the file.']);}
  finally{this.uploadBusy.set(false);}
 }
 async templateDownload(){await this.act(async()=>this.downloadTemplate());}
 visibleHomework(){return this.homework().filter(h=>(!this.campus||h['campus_id']===this.campus)&&(!this.className||h['class_name']===this.className)).sort((a,b)=>String(b['created_at']).localeCompare(String(a['created_at'])));}
 async downloadTemplate(){
  const {Workbook}=await import('exceljs');const workbook=new Workbook();const sheet=workbook.addWorksheet(this.importKind);
  sheet.addRow(columns[this.importKind]);sheet.getRow(1).font={bold:true};sheet.columns.forEach(c=>{c.width=26;c.numFmt='@';});
  const bytes=await workbook.xlsx.writeBuffer();const blob=new Blob([bytes as BlobPart],{type:'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'});
  const url=URL.createObjectURL(blob);const a=document.createElement('a');a.href=url;a.download=`${this.importKind}-template.xlsx`;a.click();URL.revokeObjectURL(url);
 }
 async commitImport(){if(!this.approved||this.problems().length||!this.preview().length)return;
  await this.act(async()=>{const result=await this.db.rpc('import_school_rows',{kind:this.importKind,rows:this.preview()});this.resetImport();this.message.set(`${result.imported} records imported.${this.importKind==='parents'?` ${result.linked} linked to confirmed accounts; ${result.pending} awaiting account setup.`:''}`);});
  // Refresh without clearing the import receipt.
  if(!this.error()){const receipt=this.message();await this.load();if(!this.error())this.message.set(receipt);}
 }
 async linkParent(id:string){await this.act(async()=>{const linked=await this.db.rpc('link_registered_parent',{contact_id:id});this.message.set(linked?'Parent account linked to this student.':'No confirmed account matches this email yet. Create the login first, then link again.');});}
 async assignTeacher(){await this.act(async()=>{await this.db.rpc('assign_teacher',{teacher_email:this.teacherEmail,target_campus:this.campus,target_class:this.className,target_year:this.academicYear.trim(),year_start:this.yearStart,year_end:this.yearEnd});this.teacherEmail='';this.message.set('Teacher assigned to this class.');});if(!this.error())await this.load();}
 async loadMarks(){this.marks.set({});if(!this.campus||!this.className)return;await this.act(async()=>{
  const {data,error}=await this.db.client.from('attendance').select('student_id,status').eq('attendance_date',this.attendanceDay).in('student_id',this.roster().map(s=>s['id']));if(error)throw error;
  this.marks.set(Object.fromEntries(data.map(r=>[r.student_id,r.status])));
 });}
 mark(id:string,status:string){this.marks.update(m=>({...m,[id]:status}));}
 markAll(){this.marks.set(Object.fromEntries(this.roster().map(s=>[s['id'],'present'])));}
 async attendanceFile(event:Event){
  const input=event.target as HTMLInputElement;const file=input.files?.[0];input.value='';if(!file)return;
  await this.act(async()=>{
   if(file.size>1024*1024||!file.name.toLowerCase().endsWith('.csv'))throw Error('Choose a CSV file smaller than 1 MB.');
   const grid=parseCsv(await file.text());
   if(grid.length<2||grid.length>501||grid[0].join(',')!=='admission_number,status')throw Error('Use the attendance template with 1 to 500 rows.');
   const next:Record<string,string>={};
   for(const [index,row] of grid.slice(1).entries()){
    if(row.length!==2)throw Error(`Row ${index+2}: expected admission_number and status.`);
    const student=this.roster().find(s=>s['admission_number']===row[0].trim());const status=row[1].trim().toLowerCase();
    if(!student)throw Error(`Row ${index+2}: admission number is not in the selected class.`);
    if(!['present','absent','late','excused'].includes(status))throw Error(`Row ${index+2}: use present, absent, late or excused.`);
    if(next[student['id']])throw Error(`Row ${index+2}: duplicate student.`);next[student['id']]=status;
   }
   this.marks.set(next);this.message.set(`${grid.length-1} attendance entries loaded for review. Check the date and remaining students, then click Save attendance.`);
  });
 }
 async saveMarks(){await this.act(async()=>{const entries=this.roster().map(s=>({student_id:s['id'],status:this.marks()[s['id']]}));if(!entries.length||entries.some(e=>!e.status))throw Error('Choose a status for every student.');const count=await this.db.rpc('record_attendance',{day:this.attendanceDay,entries});this.message.set(`Attendance saved for ${count} students.`);});}
 async publishHomework(){await this.act(async()=>{const {error}=await this.db.client.from('homework').insert({campus_id:this.campus,class_name:this.className,subject:this.subject.trim(),title:this.title.trim(),instructions:this.instructions.trim(),due_date:this.due});if(error)throw error;this.subject='';this.title='';this.instructions='';this.message.set('Homework published.');});if(!this.error())await this.load();}
}
