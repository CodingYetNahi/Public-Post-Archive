import { useEffect, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { browsePosts } from "../services/archive";
import type { ArchivePost } from "../types/archive";
import { PostCard } from "../components/PostCard";
const fields = [
  ["account", "Account ID"],
  ["from", "From date"],
  ["to", "To date"],
  ["category", "Category"],
  ["language", "Language"],
  ["postType", "Post type"],
  ["mediaType", "Media type"],
  ["hashtag", "Hashtag"],
  ["keyword", "Keyword"],
];
export default function Browse() {
  const [params, setParams] = useSearchParams(),
    [posts, setPosts] = useState<ArchivePost[]>([]),
    [meta, setMeta] = useState({ page: 1, pages: 1, count: 0 }),
    [state, setState] = useState<"loading" | "ready" | "error">("loading");
  const key = params.toString();
  useEffect(() => {
    const c = new AbortController(),
      timer = setTimeout(() => {
        setState("loading");
        browsePosts(Object.fromEntries(new URLSearchParams(key)), c.signal)
          .then(({ posts, ...m }) => {
            setPosts(posts);
            setMeta(m);
            setState("ready");
          })
          .catch(() => {
            if (!c.signal.aborted) setState("error");
          });
      }, 300);
    return () => {
      clearTimeout(timer);
      c.abort();
    };
  }, [key]);
  const set = (k: string, v: string) => {
    const n = new URLSearchParams(params);
    if (v) n.set(k, v);
    else n.delete(k);
    if (k !== "page") n.delete("page");
    setParams(n);
  };
  return (
    <main className="shell">
      <h1>Browse posts</h1>
      <form className="filters" onSubmit={(e) => e.preventDefault()}>
        <label className="wide">
          Search archive
          <input
            value={params.get("search") ?? ""}
            onChange={(e) => set("search", e.target.value)}
            placeholder="Words or quoted phrase"
          />
        </label>
        {fields.map(([k, l]) => (
          <label key={k}>
            {l}
            <input
              type={k === "from" || k === "to" ? "date" : "text"}
              value={params.get(k) ?? ""}
              onChange={(e) => set(k, e.target.value)}
            />
          </label>
        ))}
        <label>
          Contains claim
          <select
            value={params.get("claim") ?? ""}
            onChange={(e) => set("claim", e.target.value)}
          >
            <option value="">Any</option>
            <option value="true">Yes</option>
            <option value="false">No</option>
          </select>
        </label>
        <label>
          Sort
          <select
            value={params.get("sort") ?? "newest"}
            onChange={(e) => set("sort", e.target.value)}
          >
            <option value="newest">Newest</option>
            <option value="oldest">Oldest</option>
          </select>
        </label>
      </form>
      {state === "loading" && (
        <div role="status" className="skeleton">
          Loading archive…
        </div>
      )}
      {state === "error" && (
        <div role="alert" className="card">
          Archive could not be loaded.{" "}
          <button onClick={() => setParams(new URLSearchParams(params))}>
            Try again
          </button>
        </div>
      )}
      {state === "ready" && (
        <>
          <p>{meta.count} matching posts</p>
          {!posts.length ? (
            <div className="card">No published posts match these filters.</div>
          ) : (
            <div className="post-list">
              {posts.map((p) => (
                <PostCard key={p.id} post={p} />
              ))}
            </div>
          )}
          <nav className="pager" aria-label="Results pages">
            <button
              disabled={meta.page <= 1}
              onClick={() => set("page", String(meta.page - 1))}
            >
              Previous
            </button>
            <span>
              Page {meta.page} of {meta.pages}
            </span>
            <button
              disabled={meta.page >= meta.pages}
              onClick={() => set("page", String(meta.page + 1))}
            >
              Next
            </button>
          </nav>
        </>
      )}
    </main>
  );
}
