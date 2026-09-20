import { Injectable } from '@angular/core';
import { createClient } from '@supabase/supabase-js';
// Publishable client configuration only. RLS, not secrecy of this key, protects data.
const url='https://myflhqgvdahmxyridpcb.supabase.co';
const key='sb_publishable_Ho-PhxjCrwjW3WT_loiQ6A_k-bPcHqA';
export type Row=Record<string,any>;
@Injectable({providedIn:'root'})
export class SchoolData {
 readonly client=createClient(url,key);
 async all(table:string):Promise<Row[]> {
  const rows:Row[]=[];
  for(let start=0;;start+=1000){
   const {data,error}=await this.client.from(table).select('*').order('id').range(start,start+999);
   if(error)throw error; rows.push(...data); if(data.length<1000)return rows;
  }
 }
 async rpc(name:string,args:Record<string,unknown>){
  const {data,error}=await this.client.rpc(name,args);if(error)throw error;return data;
 }
}
