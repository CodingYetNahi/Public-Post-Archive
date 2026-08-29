import type { BrowseQuery } from '../services/archive'
export function parseBrowseFilters(input: string): BrowseQuery {
  const params = new URLSearchParams(input)
  const page = Number(params.get('page') || 1)
  return {
    page: Number.isInteger(page) && page > 0 ? page : 1,
    search: params.get('search') || undefined,
    account: params.get('account') || undefined,
    category: params.get('category') || undefined,
    from: /^\d{4}-\d{2}-\d{2}$/.test(params.get('from') || '') ? params.get('from')! : undefined,
    to: /^\d{4}-\d{2}-\d{2}$/.test(params.get('to') || '') ? params.get('to')! : undefined,
    claim: ['true','false'].includes(params.get('claim') || '') ? params.get('claim')! : undefined,
  }
}
export function adminGateState(userId: string | null, listedAdminId: string | null) { return !userId ? 'login' : userId === listedAdminId ? 'admin' : 'denied' }
