import { supabase } from '../lib/supabase'
import type { ArchivePost } from '../types/archive'

export interface BrowseQuery { page?: number; search?: string; account?: string; category?: string; language?: string; postType?: string; mediaType?: string; claim?: string; from?: string; to?: string; hashtag?: string; keyword?: string; sort?: 'newest'|'oldest' }
export async function browsePosts(query: BrowseQuery, signal?: AbortSignal) {
  const page = Math.max(1, query.page ?? 1), size = 12
  let request = supabase.from('archive_posts').select('*', { count: 'exact' }).eq('publication_status', 'Published')
  if (query.search) request = request.textSearch('search_vector', query.search.split(/\s+/).map(x => `${x}:*`).join(' & '), { type: 'websearch' })
  if (query.account) request = request.eq('account_id', query.account)
  if (query.category) request = request.eq('primary_category', query.category)
  if (query.language) request = request.eq('language', query.language)
  if (query.postType) request = request.eq('post_type', query.postType)
  if (query.mediaType) request = request.eq('media_type', query.mediaType)
  if (query.claim) request = request.eq('contains_claim', query.claim === 'true')
  if (query.from) request = request.gte('published_at', query.from)
  if (query.to) request = request.lte('published_at', `${query.to}T23:59:59Z`)
  if (query.hashtag) request = request.contains('hashtags', [query.hashtag])
  if (query.keyword) request = request.contains('keywords', [query.keyword])
  const { data, error, count } = await request.order('published_at', { ascending: query.sort === 'oldest' }).range((page-1)*size, page*size-1).abortSignal(signal ?? new AbortController().signal)
  if (error) throw new Error('Unable to fetch published posts.', { cause: error })
  return { posts: (data ?? []) as ArchivePost[], count: count ?? 0, page, pages: Math.max(1, Math.ceil((count ?? 0)/size)) }
}
export async function getPost(id: string) { const { data, error } = await supabase.from('archive_posts').select('*').eq('id', id).eq('publication_status','Published').maybeSingle(); if(error) throw error; return data as ArchivePost|null }
