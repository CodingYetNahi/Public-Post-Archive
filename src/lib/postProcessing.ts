import { classify, extractMetadata } from '../classifiers/rules.ts'
import type { ImportedPost } from '../types/archive.ts'

export function normaliseUrl(value?: string) {
  if (!value) return null
  const url = new URL(value); url.hash = ''; url.hostname = url.hostname.toLowerCase(); url.searchParams.sort()
  return url.toString().replace(/\/$/, '')
}
export function normaliseText(value: string) { return value.normalize('NFKC').replace(/\s+/g, ' ').trim() }
export function fingerprint(post: Pick<ImportedPost, 'accountId' | 'originalText' | 'publishedAt'>) {
  const value = `${post.accountId}|${normaliseText(post.originalText).toLowerCase()}|${post.publishedAt ?? ''}`
  let hash = 2166136261
  for (const char of value) { hash ^= char.codePointAt(0) ?? 0; hash = Math.imul(hash, 16777619) }
  return `fnv1a-${(hash >>> 0).toString(16).padStart(8, '0')}`
}
export function preparePost(post: ImportedPost, manualCategory?: string) {
  const classification = classify(post.originalText)
  const metadata = extractMetadata(post.originalText)
  return { ...post, normalisedText: normaliseText(post.originalText), originalUrlNormalised: normaliseUrl(post.originalUrl), contentFingerprint: fingerprint(post), ...metadata, category: manualCategory || classification.category, classificationMethod: manualCategory ? 'manual' : 'automatic', confidence: manualCategory ? 1 : classification.confidence, manualReviewRequired: manualCategory ? false : classification.manualReviewRequired }
}
