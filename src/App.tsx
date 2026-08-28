import { Route, Routes } from 'react-router-dom'

function ArchiveHome() {
  return (
    <main className="page-shell">
      <section className="hero" aria-labelledby="archive-title">
        <p className="eyebrow">Independent public record</p>
        <h1 id="archive-title">Public Post Archive</h1>
        <p className="introduction">
          A durable home for preserving and finding posts published in public.
        </p>
      </section>

      <section className="archive-panel" aria-labelledby="archive-status">
        <h2 id="archive-status">Archive</h2>
        <p>The archive is ready to connect to its configured data source.</p>
      </section>
    </main>
  )
}

function NotFound() {
  return (
    <main className="page-shell">
      <section className="archive-panel">
        <p className="eyebrow">404</p>
        <h1>Page not found</h1>
        <a href="#/">Return to the archive</a>
      </section>
    </main>
  )
}

export default function App() {
  return (
    <Routes>
      <Route path="/" element={<ArchiveHome />} />
      <Route path="*" element={<NotFound />} />
    </Routes>
  )
}
