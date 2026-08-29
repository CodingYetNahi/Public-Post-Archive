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

-- Non-unique lookup indexes cannot fail when the existing archive contains duplicates.
-- Duplicates can be reviewed before a later, separately-authorised uniqueness constraint.
create index if not exists archive_posts_platform_id_idx on public.archive_posts(platform_post_id) where platform_post_id is not null;
create index if not exists archive_posts_url_idx on public.archive_posts(original_url_normalised) where original_url_normalised is not null;
create index if not exists archive_posts_fingerprint_idx on public.archive_posts(content_fingerprint) where content_fingerprint is not null;
create index if not exists archive_posts_published_idx on public.archive_posts(published_at desc); create index if not exists archive_posts_account_idx on public.archive_posts(account_id); create index if not exists archive_posts_category_idx on public.archive_posts(primary_category); create index if not exists archive_posts_subcategory_idx on public.archive_posts(subcategory); create index if not exists archive_posts_language_idx on public.archive_posts(language); create index if not exists archive_posts_type_idx on public.archive_posts(post_type); create index if not exists archive_posts_media_idx on public.archive_posts(media_type); create index if not exists archive_posts_claim_idx on public.archive_posts(contains_claim); create index if not exists archive_posts_status_idx on public.archive_posts(publication_status); create index if not exists archive_posts_topics_idx on public.archive_posts using gin(topics); create index if not exists archive_posts_hashtags_idx on public.archive_posts using gin(hashtags); create index if not exists archive_posts_search_idx on public.archive_posts using gin(search_vector);

insert into public.archive_categories(name,sort_order) select name,ord from unnest(array['Economy & Jobs','Agriculture & Rural India','Governance & Administration','Parliament & Democracy','Foreign Affairs','Defence & National Security','Social Welfare','Education','Healthcare','Infrastructure & Development','Business & Industry','Technology & Digital Policy','Environment & Climate','States & Regional Issues','Elections & Campaigning','Political Criticism','Party Activities','Public Events & Speeches','Law & Justice','Social Issues','Culture & Heritage','Festivals & Greetings','Sports','Tributes & Condolences','Personal / Informal','Other']) with ordinality as x(name,ord) on conflict(name) do nothing;

alter table public.archive_posts enable row level security; alter table public.archive_accounts enable row level security; alter table public.archive_categories enable row level security; alter table public.archive_subcategories enable row level security; alter table public.archive_topics enable row level security; alter table public.archive_post_topics enable row level security; alter table public.archive_classification_rules enable row level security; alter table public.archive_imports enable row level security; alter table public.archive_import_rows enable row level security; alter table public.archive_corrections enable row level security; alter table public.archive_admins enable row level security; alter table public.archive_settings enable row level security; alter table public.archive_audit_logs enable row level security;

-- Only policies installed by this migration are replaced. Never enumerate and delete
-- unrelated production policies; operators must review verification output separately.
drop policy if exists posts_public_read on public.archive_posts;
drop policy if exists accounts_public_read on public.archive_accounts;
drop policy if exists categories_public_read on public.archive_categories;
drop policy if exists subcategories_public_read on public.archive_subcategories;
drop policy if exists topics_public_read on public.archive_topics;
drop policy if exists post_topics_public_read on public.archive_post_topics;
drop policy if exists settings_public_read on public.archive_settings;
drop policy if exists corrections_public_insert on public.archive_corrections;
drop policy if exists admins_self_read on public.archive_admins;
drop policy if exists audit_admin_read on public.archive_audit_logs;
drop policy if exists audit_admin_insert on public.archive_audit_logs;
do $$ declare t text; begin foreach t in array array['archive_posts','archive_accounts','archive_categories','archive_subcategories','archive_topics','archive_post_topics','archive_classification_rules','archive_imports','archive_import_rows','archive_corrections','archive_settings'] loop execute format('drop policy if exists %I on public.%I',t||'_admin_all',t); end loop; end $$;

create policy posts_public_read on public.archive_posts for select to anon,authenticated using (publication_status='Published' or public.is_archive_admin());
create policy accounts_public_read on public.archive_accounts for select to anon,authenticated using (true);
create policy categories_public_read on public.archive_categories for select to anon,authenticated using (is_active or public.is_archive_admin());
create policy subcategories_public_read on public.archive_subcategories for select to anon,authenticated using (is_active or public.is_archive_admin());
create policy topics_public_read on public.archive_topics for select to anon,authenticated using (is_public or public.is_archive_admin());
create policy post_topics_public_read on public.archive_post_topics for select to anon,authenticated using (exists(select 1 from public.archive_posts p where p.id=post_id and p.publication_status='Published') or public.is_archive_admin());
create policy settings_public_read on public.archive_settings for select to anon,authenticated using (is_public or public.is_archive_admin());
create policy admins_self_read on public.archive_admins for select to authenticated using (user_id=auth.uid());
do $$ declare t text; begin foreach t in array array['archive_posts','archive_accounts','archive_categories','archive_subcategories','archive_topics','archive_post_topics','archive_classification_rules','archive_imports','archive_import_rows','archive_corrections','archive_settings'] loop execute format('create policy %I on public.%I for all to authenticated using (public.is_archive_admin()) with check (public.is_archive_admin())',t||'_admin_all',t); end loop; end $$;
create policy audit_admin_read on public.archive_audit_logs for select to authenticated using(public.is_archive_admin());
create policy audit_admin_insert on public.archive_audit_logs for insert to authenticated with check(public.is_archive_admin() and actor_id=auth.uid());

-- Data API privileges are explicit; RLS remains the second enforcement layer.
revoke all on all tables in schema public from anon, authenticated;
grant select on public.archive_posts, public.archive_accounts, public.archive_categories, public.archive_subcategories, public.archive_topics, public.archive_post_topics, public.archive_settings to anon, authenticated;
grant select,insert,update,delete on public.archive_posts, public.archive_accounts, public.archive_categories, public.archive_subcategories, public.archive_topics, public.archive_post_topics, public.archive_classification_rules, public.archive_imports, public.archive_import_rows, public.archive_corrections, public.archive_settings to authenticated;
grant select,insert on public.archive_audit_logs to authenticated;
grant select on public.archive_admins to authenticated;
grant usage,select on sequence public.archive_audit_logs_id_seq to authenticated;

-- SECURITY DEFINER exposes aggregates only, so unpublished rows and reporter data never leave the function.
create or replace function public.archive_analytics(period text default 'month') returns table(bucket timestamptz, post_count bigint, claim_count bigint) language plpgsql stable security definer set search_path=public,pg_temp as $$ begin if period not in ('day','week','month','year') then raise exception 'Invalid period'; end if; return query select date_trunc(period,published_at),count(*),count(*) filter(where contains_claim) from public.archive_posts where publication_status='Published' group by 1 order by 1; end $$;
revoke all on function public.archive_analytics(text) from public;
grant execute on function public.archive_analytics(text) to anon,authenticated;

-- SECURITY DEFINER is required so anonymous reporters can insert without receiving table access.
-- Repeat identical reports are rejected server-side; production should additionally rate-limit by IP in an Edge Function/API gateway.
create or replace function public.submit_archive_correction(p_post_id uuid,p_type text,p_details text,p_email text default null) returns uuid language plpgsql security definer set search_path=public,pg_temp as $$ declare result uuid; begin
 if p_type not in ('incorrect category','incorrect date','incorrect account','broken source','duplicate entry','incorrect transcription') then raise exception 'Invalid correction type'; end if;
 if length(p_details) not between 10 and 5000 or (p_email is not null and length(p_email)>320) then raise exception 'Invalid correction fields'; end if;
 if not exists(select 1 from public.archive_posts where id=p_post_id and publication_status='Published') then raise exception 'Post not found'; end if;
 if exists(select 1 from public.archive_corrections where post_id=p_post_id and details=p_details and created_at>now()-interval '10 minutes') then raise exception 'Please wait before resubmitting'; end if;
 insert into public.archive_corrections(post_id,correction_type,details,reporter_email,status) values(p_post_id,p_type,p_details,nullif(p_email,''),'submitted') returning id into result; return result; end $$;
revoke all on function public.submit_archive_correction(uuid,text,text,text) from public;
grant execute on function public.submit_archive_correction(uuid,text,text,text) to anon,authenticated;

comment on function public.is_archive_admin() is 'SECURITY DEFINER prevents archive_admins enumeration while authorising solely with auth.uid(); never user metadata.';
comment on function public.archive_analytics(text) is 'SECURITY DEFINER returns published aggregate counts only.';
comment on function public.submit_archive_correction(uuid,text,text,text) is 'SECURITY DEFINER permits validated inserts without granting correction-table access to anonymous users.';


-- SECURITY DEFINER returns only grouped values from published posts; dimension is allow-listed.
create or replace function public.archive_distribution(dimension text) returns table(label text,item_count bigint) language plpgsql stable security definer set search_path=public,pg_temp as $$ begin
 if dimension not in ('primary_category','topics','language','post_type','media_type','contains_claim','hashtags','mentions','year') then raise exception 'Invalid dimension'; end if;
 if dimension in ('topics','hashtags','mentions') then return query execute format('select coalesce(x,''Not recorded''),count(*) from public.archive_posts p cross join lateral unnest(p.%I) x where publication_status=''Published'' group by 1 order by 2 desc limit 25',dimension);
 elsif dimension='year' then return query select extract(year from published_at)::text,count(*) from public.archive_posts where publication_status='Published' group by 1 order by 1;
 else return query execute format('select coalesce(%I::text,''Not recorded''),count(*) from public.archive_posts where publication_status=''Published'' group by 1 order by 2 desc',dimension); end if;
end $$;
revoke all on function public.archive_distribution(text) from public; grant execute on function public.archive_distribution(text) to anon,authenticated;
comment on function public.archive_distribution(text) is 'SECURITY DEFINER exposes allow-listed published aggregate distributions only.';

-- SECURITY DEFINER applies symmetric, validated filters and returns published aggregate JSON only.
create or replace function public.archive_compare(p_account uuid,p_from date default null,p_to date default null,p_category text default null) returns jsonb language sql stable security definer set search_path=public,pg_temp as $$
 with filtered as (select * from public.archive_posts where publication_status='Published' and account_id=p_account and (p_from is null or published_at>=p_from) and (p_to is null or published_at<p_to+1) and (p_category is null or primary_category=p_category)),
 cats as (select coalesce(jsonb_agg(jsonb_build_object('label',primary_category,'value',n) order by n desc),'[]') value from (select primary_category,count(*) n from filtered group by 1 limit 10)x),
 keys as (select coalesce(jsonb_agg(jsonb_build_object('label',keyword,'value',n) order by n desc),'[]') value from (select keyword,count(*) n from filtered cross join lateral unnest(keywords) keyword group by 1 order by 2 desc limit 10)x),
 freq as (select coalesce(jsonb_agg(jsonb_build_object('label',bucket,'value',n) order by bucket),'[]') value from (select to_char(date_trunc('month',published_at),'YYYY-MM') bucket,count(*) n from filtered group by 1)x)
 select jsonb_build_object('total',count(*),'originals',count(*) filter(where coalesce(post_type,'Original')='Original'),'replies',count(*) filter(where post_type='Reply'),'quotes',count(*) filter(where post_type='Quote'),'media',count(*) filter(where media_type is not null),'claims',count(*) filter(where contains_claim),'categories',(select value from cats),'keywords',(select value from keys),'frequency',(select value from freq)) from filtered $$;
revoke all on function public.archive_compare(uuid,date,date,text) from public; grant execute on function public.archive_compare(uuid,date,date,text) to anon,authenticated;
comment on function public.archive_compare(uuid,date,date,text) is 'SECURITY DEFINER exposes symmetric published aggregate comparisons only.';
