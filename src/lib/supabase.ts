import { createClient } from '@supabase/supabase-js'

export interface ArchivePost {
  id: string
  title: string
  content: string
  published: boolean
  published_at: string
  created_at: string
}

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
): Promise<ArchivePost[]> {
  const { data, error } = await supabase
    .from('archive_posts')
    .select('id, title, content, published, published_at, created_at')
    .eq('published', true)
    .order('published_at', { ascending: false })
    .abortSignal(signal)

  if (error) {
    throw new Error('Unable to fetch published posts.', { cause: error })
  }

  return data
}
