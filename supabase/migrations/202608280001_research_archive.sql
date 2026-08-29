-- Additive migration: preserves archive_accounts, archive_posts, and every existing row.
create extension if not exists pgcrypto;

alter table public.archive_posts
  add column if not exists normalised_text text,
  add column if not exists handle_snapshot text,
  add column if not exists display_name_snapshot text,
  add column if not exists imported_at timestamptz default now(),
  add column if not exists language text,
  add column if not exists post_type text,
  add column if not exists primary_category text,
  add column if not exists subcategory text,
  add column if not exists topics text[] default '{}',
  add column if not exists keywords text[] default '{}',
  add column if not exists hashtags text[] default '{}',
  add column if not exists mentions text[] default '{}',
  add column if not exists media_type text,
  add column if not exists media_urls text[] default '{}',
  add column if not exists quoted_post_url text,
  add column if not exists reply_to_url text,
  add column if not exists contains_claim boolean default false,
  add column if not exists claim_type text,
  add column if not exists claim_text text,
  add column if not exists classification_confidence numeric(4,3),
  add column if not exists classification_method text,
  add column if not exists manual_review_required boolean default true,
  add column if not exists edited_status text default 'original',
  add column if not exists source text,
  add column if not exists publication_status text default 'Draft',
  add column if not exists original_url_normalised text,
  add column if not exists content_fingerprint text,
  add column if not exists search_vector tsvector generated always as (to_tsvector('simple', coalesce(normalised_text, original_text, ''))) stored,
  add column if not exists updated_at timestamptz default now();

create table if not exists public.archive_categories (id uuid primary key default gen_random_uuid(), name text not null unique, description text, is_active boolean not null default true, sort_order integer not null default 0, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create table if not exists public.archive_subcategories (id uuid primary key default gen_random_uuid(), category_id uuid not null references public.archive_categories(id), name text not null, is_active boolean not null default true, unique(category_id,name));
create table if not exists public.archive_topics (id uuid primary key default gen_random_uuid(), slug text not null unique, name text not null unique, description text, is_public boolean not null default true, created_at timestamptz not null default now());
create table if not exists public.archive_post_topics (post_id uuid not null references public.archive_posts(id) on delete cascade, topic_id uuid not null references public.archive_topics(id), primary key(post_id,topic_id));
create table if not exists public.archive_classification_rules (id uuid primary key default gen_random_uuid(), category_id uuid references public.archive_categories(id), subcategory_id uuid references public.archive_subcategories(id), matcher_type text not null check(matcher_type in ('keyword','phrase','hashtag','entity')), pattern text not null, weight numeric not null default 1, is_active boolean not null default true, created_at timestamptz not null default now());
create table if not exists public.archive_imports (id uuid primary key default gen_random_uuid(), importer_type text not null, file_name text, status text not null default 'pending', valid_count int not null default 0, invalid_count int not null default 0, new_count int not null default 0, created_by uuid references auth.users(id), created_at timestamptz not null default now(), completed_at timestamptz);
create table if not exists public.archive_import_rows (id uuid primary key default gen_random_uuid(), import_id uuid not null references public.archive_imports(id) on delete cascade, row_number int not null, raw_data jsonb not null, status text not null, error_message text, post_id uuid references public.archive_posts(id), unique(import_id,row_number));
create table if not exists public.archive_corrections (id uuid primary key default gen_random_uuid(), post_id uuid not null references public.archive_posts(id), correction_type text not null check(correction_type in ('incorrect category','incorrect date','incorrect account','broken source','duplicate entry','incorrect transcription')), details text not null check(length(details) between 10 and 5000), reporter_email text, status text not null default 'submitted', created_at timestamptz not null default now(), reviewed_at timestamptz, reviewed_by uuid references auth.users(id));
create table if not exists public.archive_admins (user_id uuid primary key references auth.users(id) on delete cascade, added_at timestamptz not null default now(), added_by uuid references auth.users(id));
create table if not exists public.archive_settings (key text primary key, value jsonb not null, is_public boolean not null default false, updated_at timestamptz not null default now(), updated_by uuid references auth.users(id));
create table if not exists public.archive_audit_logs (id bigint generated always as identity primary key, actor_id uuid references auth.users(id), action text not null, table_name text not null, record_id text, old_data jsonb, new_data jsonb, created_at timestamptz not null default now());

create or replace function public.is_archive_admin() returns boolean language sql stable security definer set search_path=public,pg_temp as $$ select exists(select 1 from public.archive_admins where user_id=auth.uid()) $$;
revoke all on function public.is_archive_admin() from public; grant execute on function public.is_archive_admin() to anon, authenticated;

create unique index if not exists archive_posts_platform_id_unique on public.archive_posts(platform_post_id) where platform_post_id is not null;
create unique index if not exists archive_posts_url_unique on public.archive_posts(original_url_normalised) where original_url_normalised is not null;
create unique index if not exists archive_posts_fingerprint_unique on public.archive_posts(content_fingerprint) where content_fingerprint is not null;
create index if not exists archive_posts_published_idx on public.archive_posts(published_at desc); create index if not exists archive_posts_account_idx on public.archive_posts(account_id); create index if not exists archive_posts_category_idx on public.archive_posts(primary_category); create index if not exists archive_posts_subcategory_idx on public.archive_posts(subcategory); create index if not exists archive_posts_language_idx on public.archive_posts(language); create index if not exists archive_posts_type_idx on public.archive_posts(post_type); create index if not exists archive_posts_media_idx on public.archive_posts(media_type); create index if not exists archive_posts_claim_idx on public.archive_posts(contains_claim); create index if not exists archive_posts_status_idx on public.archive_posts(publication_status); create index if not exists archive_posts_topics_idx on public.archive_posts using gin(topics); create index if not exists archive_posts_hashtags_idx on public.archive_posts using gin(hashtags); create index if not exists archive_posts_search_idx on public.archive_posts using gin(search_vector);

insert into public.archive_categories(name,sort_order) select name,ord from unnest(array['Economy & Jobs','Agriculture & Rural India','Governance & Administration','Parliament & Democracy','Foreign Affairs','Defence & National Security','Social Welfare','Education','Healthcare','Infrastructure & Development','Business & Industry','Technology & Digital Policy','Environment & Climate','States & Regional Issues','Elections & Campaigning','Political Criticism','Party Activities','Public Events & Speeches','Law & Justice','Social Issues','Culture & Heritage','Festivals & Greetings','Sports','Tributes & Condolences','Personal / Informal','Other']) with ordinality as x(name,ord) on conflict(name) do nothing;

alter table public.archive_posts enable row level security; alter table public.archive_accounts enable row level security; alter table public.archive_categories enable row level security; alter table public.archive_subcategories enable row level security; alter table public.archive_topics enable row level security; alter table public.archive_post_topics enable row level security; alter table public.archive_classification_rules enable row level security; alter table public.archive_imports enable row level security; alter table public.archive_import_rows enable row level security; alter table public.archive_corrections enable row level security; alter table public.archive_admins enable row level security; alter table public.archive_settings enable row level security; alter table public.archive_audit_logs enable row level security;

-- Remove permissive policies before installing least-privilege policies.
do $$ declare r record; begin for r in select schemaname,tablename,policyname from pg_policies where schemaname='public' and tablename like 'archive_%' loop execute format('drop policy if exists %I on %I.%I',r.policyname,r.schemaname,r.tablename); end loop; end $$;
create policy posts_public_read on public.archive_posts for select using (publication_status='Published' or public.is_archive_admin());
create policy accounts_public_read on public.archive_accounts for select using (true);
create policy categories_public_read on public.archive_categories for select using (is_active or public.is_archive_admin()); create policy subcategories_public_read on public.archive_subcategories for select using (is_active or public.is_archive_admin()); create policy topics_public_read on public.archive_topics for select using (is_public or public.is_archive_admin());
create policy post_topics_public_read on public.archive_post_topics for select using (exists(select 1 from public.archive_posts p where p.id=post_id and p.publication_status='Published') or public.is_archive_admin());
create policy settings_public_read on public.archive_settings for select using (is_public or public.is_archive_admin());
create policy corrections_public_insert on public.archive_corrections for insert to anon,authenticated with check (status='submitted' and reviewed_at is null and reviewed_by is null);
create policy admins_self_read on public.archive_admins for select to authenticated using (user_id=auth.uid());
do $$ declare t text; begin foreach t in array array['archive_posts','archive_accounts','archive_categories','archive_subcategories','archive_topics','archive_post_topics','archive_classification_rules','archive_imports','archive_import_rows','archive_corrections','archive_settings'] loop execute format('create policy %I on public.%I for all to authenticated using (public.is_archive_admin()) with check (public.is_archive_admin())',t||'_admin_all',t); end loop; end $$;
create policy audit_admin_read on public.archive_audit_logs for select to authenticated using(public.is_archive_admin()); create policy audit_admin_insert on public.archive_audit_logs for insert to authenticated with check(public.is_archive_admin() and actor_id=auth.uid());

create or replace function public.archive_analytics(period text default 'month') returns table(bucket timestamptz, post_count bigint, claim_count bigint) language sql stable security definer set search_path=public,pg_temp as $$ select date_trunc(case when period in ('day','week','month','year') then period else 'month' end,published_at),count(*),count(*) filter(where contains_claim) from public.archive_posts where publication_status='Published' group by 1 order by 1 $$;
grant execute on function public.archive_analytics(text) to anon,authenticated;
