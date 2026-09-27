import {Component, Input, OnInit, inject, signal} from '@angular/core';
import {FormsModule} from '@angular/forms';
import {SchoolData, Row} from './data';
@Component({selector:'app-monthly-fees',standalone:true,imports:[FormsModule],templateUrl:'./fees.html'})
export class MonthlyFees implements OnInit {
 @Input() campuses:Row[]=[];
 readonly db=inject(SchoolData); readonly busy=signal(false); readonly error=signal(''); readonly message=signal('');
 readonly rates=signal<Row[]>([]);readonly bills=signal<Row[]>([]);readonly preview=signal<Row|null>(null);
 campus='';className='';month=new Date().toLocaleDateString('en-CA',{timeZone:'Asia/Karachi'}).slice(0,7);
 rateMonth=this.month;due=this.month+'-10';amount:number|null=null;description='Tuition fee';approved=false;
 students:Row[]=[];voidId='';reason='';
 async ngOnInit(){this.campus=this.campuses[0]?.['id']??'';await this.act(()=>this.refresh());}
 async act(fn:()=>Promise<void>){if(this.busy())return;this.busy.set(true);this.error.set('');this.message.set('');try{await fn();}catch(e){this.error.set((e as {message?:string})?.message??'Request failed. Please try again.');}finally{this.busy.set(false);}}
 async refresh(){const [rates,bills,students]=await Promise.all(['fee_rates','monthly_fee_bills','students'].map(t=>this.db.all(t)));this.rates.set(rates);this.bills.set(bills);this.students=students;}
 clearPreview(){this.preview.set(null);this.approved=false;}
 changeCampus(){this.className='';this.voidId='';this.clearPreview();}
 changeMonth(){this.due=this.month?this.month+'-10':'';this.clearPreview();}
 classes(){return [...new Set(this.students.filter(s=>s['campus_id']===this.campus).map(s=>String(s['class_name'])))].sort();}
 visibleRates(){return this.rates().filter(r=>r['campus_id']===this.campus).sort((a,b)=>String(a['class_name']).localeCompare(b['class_name'])||String(b['effective_month']).localeCompare(a['effective_month']));}
 visibleBills(){return this.bills().filter(b=>b['campus_id']===this.campus&&b['billing_month']===this.month+'-01').sort((a,b)=>Number(b['bill_number'])-Number(a['bill_number']));}
 money(n:unknown){return new Intl.NumberFormat('en-PK',{style:'currency',currency:'PKR'}).format(Number(n??0));}
 args(){return {target_campus:this.campus,fee_month:this.month+'-01',pay_by:this.due};}
 async saveRate(){await this.act(async()=>{await this.db.rpc('save_fee_rate',{target_campus:this.campus,target_class:this.className,from_month:this.rateMonth+'-01',monthly_amount:this.amount,fee_description:this.description.trim()});this.clearPreview();await this.refresh();this.message.set('Class rate saved. Existing bills keep their original amount.');});}
 editRate(r:Row){this.className=r['class_name'];this.rateMonth=String(r['effective_month']).slice(0,7);this.amount=Number(r['amount']);this.description=r['description'];this.clearPreview();}
 async review(){await this.act(async()=>{this.clearPreview();this.preview.set(await this.db.rpc('preview_monthly_fees',this.args()));});}
 async generate(){const p=this.preview();if(!p||!this.approved||p['missing']||!p['ready'])return;await this.act(async()=>{const result=await this.db.rpc('generate_monthly_fees',{...this.args(),preview_token:p['token']});this.clearPreview();await this.refresh();this.message.set(`${result.generated} bills generated, totalling ${this.money(result.total)}. ${result.skipped_existing} existing bills skipped.`);});}
 async voidBill(){if(!this.voidId)return;await this.act(async()=>{await this.db.rpc('void_monthly_fee',{bill_id:this.voidId,reason:this.reason.trim()});this.voidId='';this.reason='';this.clearPreview();await this.refresh();this.message.set('Bill voided. Its history is preserved. Preview this month again to generate a replacement.');});}
 exportBills(){const rows=[['Bill','Student','Admission number','Class','Month','Due date','Description','Amount PKR','Status','Void reason'],...this.visibleBills().map(b=>['FEE-'+b['bill_number'],b['student_name'],b['admission_number'],b['class_name'],b['billing_month'],b['due_date'],b['description'],b['amount'],b['voided_at']?'Voided':'Generated',b['void_reason']??''])];const csv=rows.map(r=>r.map(v=>{let s=String(v);if(/^[\s]*[=+@-]/.test(s))s="'"+s;return '"'+s.replaceAll('"','""')+'"';}).join(',')).join('\r\n');const url=URL.createObjectURL(new Blob(['\uFEFF'+csv],{type:'text/csv;charset=utf-8'}));const a=document.createElement('a');a.href=url;a.download=`monthly-fees-${this.month}.csv`;a.click();URL.revokeObjectURL(url);}
}
