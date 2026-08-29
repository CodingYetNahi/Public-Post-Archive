import { useState } from 'react'
import { supabase } from '../lib/supabase'
const types=['incorrect category','incorrect date','incorrect account','broken source','duplicate entry','incorrect transcription']
export default function Corrections(){
  const [status,setStatus]=useState('')
  async function submit(event:React.FormEvent<HTMLFormElement>){
    event.preventDefault(); const form=event.currentTarget; const data=new FormData(form)
    if(data.get('website')) return
    if(Date.now()-Number(localStorage.getItem('correction-at')??0)<60000){setStatus('Please wait before sending another report.');return}
    const id=String(data.get('post_id')),details=String(data.get('details')),email=String(data.get('email')||'')
    if(!/^[0-9a-f]{8}-[0-9a-f-]{27}$/i.test(id)||details.length<10||details.length>5000||email.length>320){setStatus('Please check the post ID and field lengths.');return}
    const {error}=await supabase.rpc('submit_archive_correction',{p_post_id:id,p_type:data.get('type'),p_details:details,p_email:email||null})
    if(error)setStatus('The correction could not be submitted.');else{localStorage.setItem('correction-at',String(Date.now()));setStatus('Thank you. Your correction was submitted for review.');form.reset()}
  }
  return <main className="shell"><h1>Suggest a correction</h1><form className="card form" onSubmit={submit}><label>Archive post ID<input name="post_id" required maxLength={36}/></label><label>Correction type<select name="type">{types.map(x=><option key={x}>{x}</option>)}</select></label><label>Details<textarea name="details" required minLength={10} maxLength={5000}/></label><label>Email (optional, never displayed publicly)<input name="email" type="email" maxLength={320}/></label><label className="honeypot" aria-hidden="true">Website<input name="website" tabIndex={-1} autoComplete="off"/></label><button>Submit correction</button><p role="status">{status}</p></form></main>
}
