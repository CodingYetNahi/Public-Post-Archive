import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabasePublishableKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY

if (!supabaseUrl || !supabasePublishableKey) {
  throw new Error(
    'Missing VITE_SUPABASE_URL or VITE_SUPABASE_PUBLISHABLE_KEY environment variable.',
  )
}

export const supabase = createClient(supabaseUrl, supabasePublishableKey)

export interface Post {
  id: string
  title: string
  content: string
  published: boolean
  published_at: string
  created_at: string
}

export async function fetchPublishedPosts(): Promise<Post[]> {
  const { data, error } = await supabase
    .from('posts')
    .select('id, title, content, published, published_at, created_at')
    .eq('published', true)
    .order('published_at', { ascending: false })

  if (error) {
    throw error
  }

  return data
}
