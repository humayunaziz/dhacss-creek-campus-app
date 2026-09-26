export type ImportKind = 'campuses' | 'students' | 'parents';
export type ImportRow = Record<string, string>;
export const columns: Record<ImportKind, string[]> = {
 campuses: ['campus_code','campus_name'],
 students: ['campus_code','admission_number','student_name','class_name','status'],
 parents: ['campus_code','admission_number','parent_name','parent_email','phone'],
};
// RFC 4180 fields, including quoted commas, newlines and escaped quotes.
export function parseCsv(text: string): string[][] {
 const rows: string[][]=[]; let row: string[]=[], field='', quoted=false, closed=false;
 text=text.replace(/^\uFEFF/,'');
 for(let i=0;i<text.length;i++) {
  const c=text[i];
  if(quoted) { if(c==='"') { if(text[i+1]==='"'){field+='"';i++;}else{quoted=false;closed=true;} }else field+=c; }
  else if(c==='"') { if(field || closed) throw Error('Unexpected quote in CSV'); quoted=true; }
  else if(c===',' || c==='\n' || c==='\r') { row.push(field);field='';closed=false;if(c!==','){rows.push(row);row=[];if(c==='\r'&&text[i+1]==='\n')i++;} }
  else {if(closed)throw Error('Unexpected text after closing quote');field+=c;}
 }
 if(quoted)throw Error('Unclosed quote in CSV');
 if(field || row.length || closed){row.push(field);rows.push(row);}
 return rows.filter(r=>r.some(v=>v.trim()));
}
export function validateImport(kind: ImportKind, grid: string[][]): {rows: ImportRow[],errors:string[]} {
 const errors:string[]=[], rows:ImportRow[]=[];
 if(!grid.length)return {rows,errors:['The file is empty.']};
 const header=grid[0].map(v=>v.trim().toLowerCase()); const required=columns[kind].filter(c=>c!=='status');
 if((header.length<required.length || header.some(c=>!columns[kind].includes(c))) || new Set(header).size!==header.length || required.some(c=>!header.includes(c)))
  return {rows,errors:[`Use these exact columns: ${required.join(', ')}`]};
 if(grid.length<2 || grid.length>501)errors.push('Include between 1 and 500 data rows.');
 const seen=new Set<string>();
 const limits:Record<string,number>={campus_code:30,campus_name:120,admission_number:50,student_name:120,class_name:50,parent_name:120,parent_email:254,phone:40,status:20};
 grid.slice(1).forEach((values,i)=>{
  const row:ImportRow={};
  if(values.length!==header.length)errors.push(`Row ${i+2}: column count does not match the template.`);
  header.forEach((key,j)=>{row[key]=(values[j]??'').trim(); if(key==='parent_email')row[key]=row[key].toLowerCase();
   if(!row[key]&&key!=='phone'&&key!=='status')errors.push(`Row ${i+2}: ${key} is required.`);
   if(row[key].length>limits[key])errors.push(`Row ${i+2}: ${key} is too long.`);
   if(/^[=+@]/.test(row[key]) && key!=='phone'&&key!=='status')errors.push(`Row ${i+2}: ${key} must be plain text, not a formula.`);
  });
  if(kind==='students'){row['status']=(row['status']||'active').toLowerCase();if(!['active','transferred','suspended','inactive','left'].includes(row['status']))errors.push(`Row ${i+2}: invalid student status.`);}
  if(kind==='parents'&&!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(row['parent_email']))errors.push(`Row ${i+2}: invalid parent email.`);
  const key=JSON.stringify([row['campus_code'],kind==='campuses'?'':row['admission_number'],kind==='parents'?row['parent_email']:'']);
  if(seen.has(key))errors.push(`Row ${i+2}: duplicate record within this file.`);seen.add(key);rows.push(row);
 });
 return {rows,errors};
}
