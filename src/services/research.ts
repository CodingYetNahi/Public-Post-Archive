import { supabase } from '../lib/supabase'
export type Account = { id: string; display_name?: string; handle?: string }
export async function getAccounts() { const { data, error } = await supabase.from('archive_accounts').select('*').order('display_name'); if (error) throw error; return (data ?? []) as Account[] }
export async function getCategories() { const { data, error } = await supabase.from('archive_categories').select('name').eq('is_active', true).order('sort_order'); if (error) throw error; return (data ?? []).map(x => x.name as string) }
export async function timeline(period: string) { const { data, error } = await supabase.rpc('archive_analytics', { period }); if (error) throw error; return (data ?? []).map((x: { bucket: string; post_count: number }) => ({ label: new Date(x.bucket).toLocaleDateString(), value: Number(x.post_count), date: x.bucket })) }
export async function distribution(dimension: string) { const { data, error } = await supabase.rpc('archive_distribution', { dimension }); if (error) throw error; return (data ?? []).map((x: { label: string; item_count: number }) => ({ label: x.label || 'Not recorded', value: Number(x.item_count) })) }
