import { useEffect, useState } from 'react'
import { Route, Routes } from 'react-router-dom'
import {
  fetchPublishedPosts,
  type PublishedArchivePost,
} from './lib/supabase'

const dateFormatter = new Intl.DateTimeFormat(undefined, { dateStyle: 'long' })

function PostAuthor({ post }: { post: PublishedArchivePost }) {
  return (
    <p className="post-author">
      <span>{post.display_name_snapshot}</span>
      <span className="post-handle">@{post.handle_snapshot.replace(/^@/, '')}</span>
    </p>
  )
}

function PostMetadata({ post }: { post: PublishedArchivePost }) {
  const metadata = [
    post.primary_category,
    post.post_type,
    post.published_at ? dateFormatter.format(new Date(post.published_at)) : null,
  ].filter((value): value is string => Boolean(value))

  if (metadata.length === 0) return null

  return (
    <ul className="post-metadata" aria-label="Post details">
      {metadata.map((item) => <li key={item}>{item}</li>)}
    </ul>
  )
}

function ArchiveHome() {
  const [posts, setPosts] = useState<PublishedArchivePost[]>([])
  const [isLoading, setIsLoading] = useState(true)
  const [errorMessage, setErrorMessage] = useState<string | null>(null)
  const [loadAttempt, setLoadAttempt] = useState(0)

  useEffect(() => {
    const controller = new AbortController()

    async function loadPosts() {
      setIsLoading(true)
      setErrorMessage(null)

      try {
        const publishedPosts = await fetchPublishedPosts(controller.signal)
        setPosts(publishedPosts)
      } catch (error) {
        if (!controller.signal.aborted) {
          setErrorMessage(
            error instanceof Error
              ? error.message
              : 'The archive could not be loaded. Please try again later.',
          )
        }
      } finally {
        if (!controller.signal.aborted) {
          setIsLoading(false)
        }
      }
    }

    void loadPosts()

    return () => {
      controller.abort()
    }
  }, [loadAttempt])

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
        {!isLoading && errorMessage && (
          <div className="error-state" role="alert">
            <p>{errorMessage}</p>
            <button
              type="button"
              onClick={() => setLoadAttempt((attempt) => attempt + 1)}
            >
              Try again
            </button>
          </div>
        )}
        {!isLoading && !errorMessage && posts.length === 0 && (
          <p>No published posts are available yet.</p>
        )}
        {!isLoading && !errorMessage && posts.length > 0 && (
          <div className="post-list">
            {posts.map((post) => (
              <article className="post" key={post.id}>
                <PostAuthor post={post} />
                <PostMetadata post={post} />
                <p className="post-text">{post.original_text}</p>
                {post.original_url && (
                  <a href={post.original_url} target="_blank" rel="noreferrer">
                    View original on X
                  </a>
                )}
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
