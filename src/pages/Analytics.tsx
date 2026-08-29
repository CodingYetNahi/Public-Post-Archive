import { useEffect, useState } from 'react'
import { BarChart, type ChartDatum } from '../components/BarChart'
import { distribution } from '../services/research'
const dimensions = [['primary_category','Category'],['topics','Topic'],['language','Language'],['post_type','Post type'],['media_type','Media'],['contains_claim','Claims detected'],['hashtags','Hashtag'],['mentions','Mention']]
export default function Analytics() {
  const [results,setResults]=useState<Record<string,ChartDatum[]>>({}); const [error,setError]=useState('')
  useEffect(()=>{ Promise.all(dimensions.map(async ([key])=>[key,await distribution(key)] as const)).then(items=>setResults(Object.fromEntries(items))).catch(()=>setError('Analytics could not be loaded.')) },[])
  return <main className="shell"><h1>Analytics</h1><p>Neutral aggregate counts from published records. Bars show absolute counts; each row also shows its percentage of that distribution.</p>{error?<p role="alert">{error}</p>:<div className="analytics-grid">{dimensions.map(([key,label])=>{ const rows=results[key]??[],total=rows.reduce((n,x)=>n+x.value,0); return <BarChart key={key} title={label} data={rows.map(x=>({...x,label:`${x.label} (${total?Math.round(x.value/total*100):0}%)`}))}/> })}</div>}</main>
}
