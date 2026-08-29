export interface ArchivePost {
  id: string; platform_post_id: string | null; account_id: string; handle_snapshot: string
  display_name_snapshot: string; original_text: string; normalised_text: string | null
  original_url: string | null; published_at: string | null; imported_at: string; language: string | null
  post_type: string | null; primary_category: string | null; subcategory: string | null
  topics: string[] | null; keywords: string[] | null; hashtags: string[] | null; mentions: string[] | null
  media_type: string | null; media_urls: string[] | null; quoted_post_url: string | null; reply_to_url: string | null
  contains_claim: boolean | null; claim_type: string | null; claim_text: string | null
  classification_confidence: number | null; classification_method: string | null
  manual_review_required: boolean | null; edited_status: string | null; publication_status: string
  source: string | null; created_at: string; updated_at: string
}
export interface ImportedPost { originalText: string; originalUrl?: string; platformPostId?: string; accountId: string; publishedAt?: string; language?: string }
export interface ImportResult { valid: ImportedPost[]; rejected: { row: number; reason: string }[] }
