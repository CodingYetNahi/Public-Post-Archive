import { useEffect, useState } from 'react'
import { Route, Routes } from 'react-router-dom'
import {
  fetchPublishedPosts,
  type ArchivePost,
} from './lib/supabase'

function ArchiveHome() {
  const [posts, setPosts] = useState<ArchivePost[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)

  useEffect(() => {
    let isCurrent = true

    async function loadPosts() {
      try {
        const publishedPosts = await fetchPublishedPosts()

        if (isCurrent) {
          setPosts(publishedPosts)
        }
      } catch {
        if (isCurrent) {
          setErrorMessage('The archive could not be loaded. Please try again later.')
        }
      } finally {
        if (isCurrent) {
          setIsLoading(false)
        }
      }
    }

    void loadPosts()

    return () => {
      isCurrent = false
    }
  }, [])

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
        {isLoading && <p role="status">Loading published posts…</p>}
        {!isLoading && errorMessage && <p role="alert">{errorMessage}</p>}
        {!isLoading && !errorMessage && posts.length === 0 && (
          <p>No published posts are available yet.</p>
        )}
        {!isLoading && !errorMessage && posts.length > 0 && (
          <div className="post-list">
            {posts.map((post) => (
              <article className="post" key={post.id}>
                <h3>{post.title}</h3>
                <p className="post-date">
                  <time dateTime={post.published_at}>
                    {new Intl.DateTimeFormat(undefined, {
                      dateStyle: 'long',
                    }).format(new Date(post.published_at))}
                  </time>
                </p>
                <p>{post.content}</p>
              </article>
            ))}
          </div>
        )}
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
