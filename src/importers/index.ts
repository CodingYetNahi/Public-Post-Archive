import type { ImportedPost, ImportResult } from '../types/archive'

export interface PostImporter { importPosts(input: unknown): Promise<ImportedPost[]> }

export function validateRecord(value: unknown): ImportedPost {
  if (!value || typeof value !== 'object' || Array.isArray(value)) throw new Error('Record must be an object')
  const row = value as Record<string, unknown>
  const originalText = row.originalText ?? row.original_text
  const accountId = row.accountId ?? row.account_id
  if (typeof originalText !== 'string' || !originalText.trim()) throw new Error('originalText is required')
  if (typeof accountId !== 'string' || !accountId.trim()) throw new Error('accountId is required')
  const string = (camel: string, snake: string) => {
    const item = row[camel] ?? row[snake]
    return typeof item === 'string' && item.trim() ? item.trim() : undefined
  }
  const originalUrl = string('originalUrl', 'original_url')
  if (originalUrl) { try { new URL(originalUrl) } catch { throw new Error('originalUrl must be a valid URL') } }
  return {
    originalText: originalText.trim(), accountId: accountId.trim(),
    ...(originalUrl ? { originalUrl } : {}),
    ...(string('platformPostId', 'platform_post_id') ? { platformPostId: string('platformPostId', 'platform_post_id') } : {}),
    ...(string('publishedAt', 'published_at') ? { publishedAt: string('publishedAt', 'published_at') } : {}),
    ...(string('language', 'language') ? { language: string('language', 'language') } : {}),
  }
}

/** RFC 4180-style parser supporting UTF-8 text, CRLF, escaped quotes and quoted newlines. */
export function parseCsv(input: string): string[][] {
  const text = input.replace(/^\uFEFF/, '')
  const rows: string[][] = []; let row: string[] = []; let field = ''; let quoted = false
  for (let index = 0; index < text.length; index += 1) {
    const char = text[index]
    if (quoted) {
      if (char === '"' && text[index + 1] === '"') { field += '"'; index += 1 }
      else if (char === '"') quoted = false
      else field += char
    } else if (char === '"' && field === '') quoted = true
    else if (char === ',') { row.push(field); field = '' }
    else if (char === '\n' || char === '\r') {
      if (char === '\r' && text[index + 1] === '\n') index += 1
      row.push(field); rows.push(row); row = []; field = ''
    } else field += char
  }
  if (quoted) throw new Error('CSV contains an unterminated quoted field')
  if (field || row.length) { row.push(field); rows.push(row) }
  return rows.filter((values) => values.some((value) => value.length > 0))
}

export function parseCsvObjects(input: string): Record<string, string>[] {
  const [headers, ...rows] = parseCsv(input)
  if (!headers?.length) throw new Error('CSV header row is required')
  const names = headers.map((value) => value.trim())
  if (new Set(names).size !== names.length) throw new Error('CSV headers must be unique')
  return rows.map((values) => Object.fromEntries(names.map((name, index) => [name, values[index] ?? ''])))
}

export function validateBatch(rows: unknown[]): ImportResult {
  const valid: ImportedPost[] = []; const rejected: ImportResult['rejected'] = []
  rows.forEach((row, index) => { try { valid.push(validateRecord(row)) } catch (error) { rejected.push({ row: index + 1, reason: error instanceof Error ? error.message : 'Invalid row' }) } })
  return { valid, rejected }
}

export class ManualImporter implements PostImporter { async importPosts(input: unknown) { return [validateRecord(input)] } }
export class JsonImporter implements PostImporter {
  async importPosts(input: unknown) {
    const parsed = typeof input === 'string' ? JSON.parse(input) : input
    if (!Array.isArray(parsed)) throw new Error('JSON input must be an array')
    return parsed.map(validateRecord)
  }
}
export class CsvImporter implements PostImporter { async importPosts(input: unknown) { if (typeof input !== 'string') throw new Error('CSV input must be text'); return parseCsvObjects(input).map(validateRecord) } }
export interface AuthorisedSourceAdapter extends PostImporter { readonly sourceName: string; isConfigured(): boolean }
