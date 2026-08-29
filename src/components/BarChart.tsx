import { Link } from 'react-router-dom'
export interface ChartDatum { label: string; value: number; href?: string }
export function BarChart({ data, title }: { data: ChartDatum[]; title: string }) {
  const maximum = Math.max(1, ...data.map((item) => item.value))
  return <section className="card chart" aria-label={title}><h2>{title}</h2>{data.length ? data.map((item) => <div className="bar-row" key={item.label}><span>{item.href ? <Link to={item.href}>{item.label}</Link> : item.label}</span><div className="bar-track"><span style={{ width: `${item.value / maximum * 100}%` }} /></div><strong>{item.value}</strong></div>) : <p>No published data matches these filters.</p>}</section>
}
