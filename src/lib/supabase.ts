import { createClient } from '@supabase/supabase-js'
import type { ArchivePost } from '../types/archive'

const url = import.meta.env.VITE_SUPABASE_URL
const key = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY
if (!url || !key) throw new Error('Missing VITE_SUPABASE_URL or VITE_SUPABASE_PUBLISHABLE_KEY environment variable.')
export const supabase = createClient(url, key)
export type PublishedArchivePost = ArchivePost
