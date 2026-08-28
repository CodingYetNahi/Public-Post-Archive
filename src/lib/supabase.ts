import { createClient } from '@supabase/supabase-js'

export interface ArchivePost {
  id: string
  platform_post_id: string
  account_id: string
  handle_snapshot: string
  display_name_snapshot: string
  original_text: string
  normalised_text: string | null
  original_url: string | null
  published_at: string | null
  imported_at: string
  language: string | null
  post_type: string | null
  primary_category: string | null
  subcategory: string | null
  topics: string[] | null
  keywords: string[] | null
  hashtags: string[] | null
  mentions: string[] | null
  media_type: string | null
  media_urls: string[] | null
  quoted_post_url: string | null
  reply_to_url: string | null
  contains_claim: boolean | null
  claim_type: string | null
  claim_text: string | null
  classification_confidence: number | null
  classification_method: string | null
  manual_review_required: boolean | null
  publication_status: string
  source: string | null
  created_at: string
  updated_at: string
}

export type PublishedArchivePost = Pick<
  ArchivePost,
  | 'id'
  | 'platform_post_id'
  | 'account_id'
  | 'handle_snapshot'
  | 'display_name_snapshot'
  | 'original_text'
  | 'original_url'
  | 'published_at'
  | 'language'
  | 'post_type'
  | 'primary_category'
  | 'subcategory'
  | 'topics'
  | 'hashtags'
  | 'media_type'
  | 'contains_claim'
  | 'publication_status'
>

interface Database {
  public: {
    Tables: {
      archive_posts: {
        Row: ArchivePost
        Insert: Omit<ArchivePost, 'id' | 'created_at'> & {
          id?: string
          created_at?: string
        }
        Update: Partial<ArchivePost>
        Relationships: []
      }
    }
    Views: Record<string, never>
    Functions: Record<string, never>
    Enums: Record<string, never>
    CompositeTypes: Record<string, never>
  }
}

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabasePublishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!supabaseUrl || !supabasePublishableKey) {
  throw new Error(
    'Missing VITE_SUPABASE_URL or VITE_SUPABASE_PUBLISHABLE_KEY environment variable.',
  )
}

export const supabase = createClient<Database>(
  supabaseUrl,
  supabasePublishableKey,
)

export async function fetchPublishedPosts(
  signal: AbortSignal,
): Promise<PublishedArchivePost[]> {
  const { data, error } = await supabase
    .from('archive_posts')
    .select('id, platform_post_id, account_id, handle_snapshot, display_name_snapshot, original_text, original_url, published_at, language, post_type, primary_category, subcategory, topics, hashtags, media_type, contains_claim, publication_status')
    .eq('publication_status', 'Published')
    .order('published_at', { ascending: false })
    .abortSignal(signal)

  if (error) {
    if (import.meta.env.DEV) {
      console.error('Supabase archive_posts fetch failed:', error)
    }
    throw new Error('Unable to fetch published posts.', { cause: error })
  }

  return data
}
