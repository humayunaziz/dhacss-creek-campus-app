import {test} from 'node:test';
import assert from 'node:assert/strict';
import {parseCsv,validateImport} from './import.ts';
test('CSV preserves quoted commas, escaped quotes, multiline names and leading zeros',()=>{
 const grid=parseCsv('\uFEFFcampus_code,campus_name\r\n001,"Creek, Campus"\r\n002,"A ""quoted""\nname"\r\n');
 assert.deepEqual(grid[1],['001','Creek, Campus']);assert.deepEqual(grid[2],['002','A "quoted"\nname']);
 assert.equal(validateImport('campuses',grid).errors.length,0);
});
test('invalid quoting is rejected instead of silently corrupting records',()=>{
 assert.throws(()=>parseCsv('a,b\n"open,x'));assert.throws(()=>parseCsv('a,b\n"closed"oops,x'));
});
test('student duplicates use campus plus admission number, not admission alone',()=>{
 const valid=parseCsv('campus_code,admission_number,student_name,class_name\nA,001,First,One\nB,001,Second,One');
 assert.equal(validateImport('students',valid).errors.length,0);
 valid.push(['A','001','Other','Two']);assert.match(validateImport('students',valid).errors.join(),/duplicate/);
});
test('parent email is normalized; multiple children can share a parent email',()=>{
 const result=validateImport('parents',parseCsv('campus_code,admission_number,parent_name,parent_email,phone\nA,001,Parent,PARENT@EXAMPLE.COM,+923001234567\nA,002,Parent,parent@example.com,0123'));
 assert.equal(result.errors.length,0);assert.equal(result.rows[0]['parent_email'],'parent@example.com');assert.equal(result.rows[1]['phone'],'0123');
});
test('wrong headers, incomplete records, excessive rows and invalid emails are rejected',()=>{
 assert.ok(validateImport('campuses',[['name'],['Creek']]).errors.length);
 assert.ok(validateImport('students',[['campus_code','admission_number','student_name','class_name'],['A','1','Name']]).errors.length);
 assert.ok(validateImport('parents',parseCsv('campus_code,admission_number,parent_name,parent_email,phone\nA,001,Parent,invalid,')).errors.length);
 assert.match(validateImport('campuses',[['campus_code','campus_name'],...Array.from({length:501},(_,i)=>[`${i}`,'Campus'])]).errors.join(),/500/);
});
test('formula-like values and overlong names are rejected',()=>{
 assert.ok(validateImport('campuses',[['campus_code','campus_name'],['A','=SUM(1)']]).errors.length);
 assert.ok(validateImport('campuses',[['campus_code','campus_name'],['A','X'.repeat(121)]]).errors.length);
});
