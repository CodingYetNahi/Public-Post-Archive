import { useEffect, useState } from 'react'
import { BarChart, type ChartDatum } from '../components/BarChart'
import { timeline } from '../services/research'
export default function Timeline() {
  const [period, setPeriod] = useState('month'); const [data, setData] = useState<ChartDatum[]>([]); const [error, setError] = useState('')
  useEffect(() => { timeline(period).then(rows => setData(rows.map((row: { label: string; value: number; date: string }) => ({ ...row, href: `/browse?from=${row.date.slice(0, 10)}` })))).catch(() => setError('Timeline data could not be loaded.')) }, [period])
  return <main className="shell"><h1>Timeline</h1><p>Absolute publication counts for published archive records.</p><label className="compact">Group by<select value={period} onChange={e => setPeriod(e.target.value)}><option value="day">Daily</option><option value="week">Weekly</option><option value="month">Monthly</option><option value="year">Yearly</option></select></label>{error ? <p role="alert">{error}</p> : <BarChart title="Posts over time" data={data} />}</main>
}
