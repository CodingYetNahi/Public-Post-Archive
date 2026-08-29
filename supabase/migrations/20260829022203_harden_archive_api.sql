-- Follow-up for production databases that already recorded migration 202608280001.
-- This migration is additive, preserves all archive records, and never changes
-- privileges on unrelated public-schema tables.

-- Backfill search-only and duplicate-review metadata without changing original text.
update public.archive_posts
set normalised_text = lower(regexp_replace(btrim(original_text), '\s+', ' ', 'g'))
where normalised_text is null or btrim(normalised_text) = '';

update public.archive_posts
set original_url_normalised = regexp_replace(lower(btrim(original_url)), '[?#].*$', '')
where original_url is not null
  and (original_url_normalised is null or btrim(original_url_normalised) = '');

update public.archive_posts
set content_fingerprint = encode(
  digest(
    account_id::text || '|' || lower(regexp_replace(btrim(original_text), '\s+', ' ', 'g')) || '|' || published_at::date::text,
    'sha256'
  ),
  'hex'
)
where content_fingerprint is null;

-- Remove one duplicate timestamp index while retaining the pre-existing index.
drop index if exists public.archive_posts_published_idx;

-- Cover foreign keys used by administration and deletion checks.
create index if not exists archive_subcategories_category_id_idx on public.archive_subcategories(category_id);
create index if not exists archive_post_topics_topic_id_idx on public.archive_post_topics(topic_id);
create index if not exists archive_classification_rules_category_id_idx on public.archive_classification_rules(category_id);
create index if not exists archive_classification_rules_subcategory_id_idx on public.archive_classification_rules(subcategory_id);
create index if not exists archive_imports_created_by_idx on public.archive_imports(created_by);
create index if not exists archive_import_rows_post_id_idx on public.archive_import_rows(post_id);
create index if not exists archive_corrections_post_id_idx on public.archive_corrections(post_id);
create index if not exists archive_corrections_reviewed_by_idx on public.archive_corrections(reviewed_by);
create index if not exists archive_admins_added_by_idx on public.archive_admins(added_by);
create index if not exists archive_settings_updated_by_idx on public.archive_settings(updated_by);
create index if not exists archive_audit_logs_actor_id_idx on public.archive_audit_logs(actor_id);

create or replace function public.is_archive_admin()
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, pg_temp
as $$
  select exists (
    select 1
    from public.archive_admins
    where user_id = (select auth.uid())
  )
$$;

revoke all on function public.is_archive_admin() from public;
grant execute on function public.is_archive_admin() to anon, authenticated;

-- Replace only archive-owned policies, and separate public reads from admin writes.
drop policy if exists posts_public_read on public.archive_posts;
drop policy if exists archive_posts_admin_all on public.archive_posts;
drop policy if exists accounts_public_read on public.archive_accounts;
drop policy if exists archive_accounts_admin_all on public.archive_accounts;
drop policy if exists categories_public_read on public.archive_categories;
drop policy if exists archive_categories_admin_all on public.archive_categories;
drop policy if exists subcategories_public_read on public.archive_subcategories;
drop policy if exists archive_subcategories_admin_all on public.archive_subcategories;
drop policy if exists topics_public_read on public.archive_topics;
drop policy if exists archive_topics_admin_all on public.archive_topics;
drop policy if exists post_topics_public_read on public.archive_post_topics;
drop policy if exists archive_post_topics_admin_all on public.archive_post_topics;
drop policy if exists archive_classification_rules_admin_all on public.archive_classification_rules;
drop policy if exists archive_imports_admin_all on public.archive_imports;
drop policy if exists archive_import_rows_admin_all on public.archive_import_rows;
drop policy if exists corrections_public_insert on public.archive_corrections;
drop policy if exists archive_corrections_admin_all on public.archive_corrections;
drop policy if exists settings_public_read on public.archive_settings;
drop policy if exists archive_settings_admin_all on public.archive_settings;
drop policy if exists admins_self_read on public.archive_admins;
drop policy if exists audit_admin_read on public.archive_audit_logs;
drop policy if exists audit_admin_insert on public.archive_audit_logs;

create policy posts_anon_read on public.archive_posts for select to anon
using (publication_status = 'Published');
create policy posts_authenticated_read on public.archive_posts for select to authenticated
using (publication_status = 'Published' or public.is_archive_admin());
create policy posts_admin_insert on public.archive_posts for insert to authenticated
with check (public.is_archive_admin());
create policy posts_admin_update on public.archive_posts for update to authenticated
using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy posts_admin_delete on public.archive_posts for delete to authenticated
using (public.is_archive_admin());

create policy accounts_anon_read on public.archive_accounts for select to anon using (true);
create policy accounts_authenticated_read on public.archive_accounts for select to authenticated using (true);
create policy accounts_admin_insert on public.archive_accounts for insert to authenticated with check (public.is_archive_admin());
create policy accounts_admin_update on public.archive_accounts for update to authenticated using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy accounts_admin_delete on public.archive_accounts for delete to authenticated using (public.is_archive_admin());

create policy categories_anon_read on public.archive_categories for select to anon using (is_active);
create policy categories_authenticated_read on public.archive_categories for select to authenticated using (is_active or public.is_archive_admin());
create policy categories_admin_insert on public.archive_categories for insert to authenticated with check (public.is_archive_admin());
create policy categories_admin_update on public.archive_categories for update to authenticated using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy categories_admin_delete on public.archive_categories for delete to authenticated using (public.is_archive_admin());

create policy subcategories_anon_read on public.archive_subcategories for select to anon using (is_active);
create policy subcategories_authenticated_read on public.archive_subcategories for select to authenticated using (is_active or public.is_archive_admin());
create policy subcategories_admin_insert on public.archive_subcategories for insert to authenticated with check (public.is_archive_admin());
create policy subcategories_admin_update on public.archive_subcategories for update to authenticated using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy subcategories_admin_delete on public.archive_subcategories for delete to authenticated using (public.is_archive_admin());

create policy topics_anon_read on public.archive_topics for select to anon using (is_public);
create policy topics_authenticated_read on public.archive_topics for select to authenticated using (is_public or public.is_archive_admin());
create policy topics_admin_insert on public.archive_topics for insert to authenticated with check (public.is_archive_admin());
create policy topics_admin_update on public.archive_topics for update to authenticated using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy topics_admin_delete on public.archive_topics for delete to authenticated using (public.is_archive_admin());

create policy post_topics_anon_read on public.archive_post_topics for select to anon
using (exists (select 1 from public.archive_posts p where p.id = post_id and p.publication_status = 'Published'));
create policy post_topics_authenticated_read on public.archive_post_topics for select to authenticated
using (exists (select 1 from public.archive_posts p where p.id = post_id and p.publication_status = 'Published') or public.is_archive_admin());
create policy post_topics_admin_insert on public.archive_post_topics for insert to authenticated with check (public.is_archive_admin());
create policy post_topics_admin_update on public.archive_post_topics for update to authenticated using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy post_topics_admin_delete on public.archive_post_topics for delete to authenticated using (public.is_archive_admin());

create policy classification_rules_admin_all on public.archive_classification_rules for all to authenticated
using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy imports_admin_all on public.archive_imports for all to authenticated
using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy import_rows_admin_all on public.archive_import_rows for all to authenticated
using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy corrections_admin_all on public.archive_corrections for all to authenticated
using (public.is_archive_admin()) with check (public.is_archive_admin());

create policy settings_anon_read on public.archive_settings for select to anon using (is_public);
create policy settings_authenticated_read on public.archive_settings for select to authenticated using (is_public or public.is_archive_admin());
create policy settings_admin_insert on public.archive_settings for insert to authenticated with check (public.is_archive_admin());
create policy settings_admin_update on public.archive_settings for update to authenticated using (public.is_archive_admin()) with check (public.is_archive_admin());
create policy settings_admin_delete on public.archive_settings for delete to authenticated using (public.is_archive_admin());

create policy admins_self_read on public.archive_admins for select to authenticated
using (user_id = (select auth.uid()));
create policy audit_admin_read on public.archive_audit_logs for select to authenticated
using (public.is_archive_admin());
create policy audit_admin_insert on public.archive_audit_logs for insert to authenticated
with check (public.is_archive_admin() and actor_id = (select auth.uid()));

-- Least-privilege Data API grants, scoped only to archive tables.
revoke all on table
  public.archive_posts,
  public.archive_accounts,
  public.archive_categories,
  public.archive_subcategories,
  public.archive_topics,
  public.archive_post_topics,
  public.archive_classification_rules,
  public.archive_imports,
  public.archive_import_rows,
  public.archive_corrections,
  public.archive_admins,
  public.archive_settings,
  public.archive_audit_logs
from anon, authenticated;

grant select on public.archive_posts, public.archive_accounts, public.archive_categories,
  public.archive_subcategories, public.archive_topics, public.archive_post_topics,
  public.archive_settings to anon, authenticated;
grant insert, update, delete on public.archive_posts, public.archive_accounts,
  public.archive_categories, public.archive_subcategories, public.archive_topics,
  public.archive_post_topics, public.archive_classification_rules, public.archive_imports,
  public.archive_import_rows, public.archive_corrections, public.archive_settings to authenticated;
grant select on public.archive_classification_rules, public.archive_imports,
  public.archive_import_rows, public.archive_corrections, public.archive_admins,
  public.archive_audit_logs to authenticated;
grant insert on public.archive_audit_logs to authenticated;
grant usage, select on sequence public.archive_audit_logs_id_seq to authenticated;

create or replace function public.archive_analytics(period text default 'month')
returns table(bucket timestamptz, post_count bigint, claim_count bigint)
language plpgsql stable security invoker
set search_path = pg_catalog, public, pg_temp
as $$
begin
  if period not in ('day', 'week', 'month', 'year') then
    raise exception 'Invalid period';
  end if;
  return query
    select date_trunc(period, published_at), count(*), count(*) filter (where contains_claim)
    from public.archive_posts
    where publication_status = 'Published'
    group by 1 order by 1;
end
$$;

create or replace function public.archive_distribution(dimension text)
returns table(label text, item_count bigint)
language plpgsql stable security invoker
set search_path = pg_catalog, public, pg_temp
as $$
begin
  if dimension not in ('primary_category','topics','language','post_type','media_type','contains_claim','hashtags','mentions','year') then
    raise exception 'Invalid dimension';
  end if;
  if dimension in ('topics','hashtags','mentions') then
    return query execute format(
      'select coalesce(x,''Not recorded''),count(*) from public.archive_posts p cross join lateral unnest(p.%I) x where publication_status=''Published'' group by 1 order by 2 desc limit 25',
      dimension
    );
  elsif dimension = 'year' then
    return query select extract(year from published_at)::text, count(*)
      from public.archive_posts where publication_status = 'Published' group by 1 order by 1;
  else
    return query execute format(
      'select coalesce(%I::text,''Not recorded''),count(*) from public.archive_posts where publication_status=''Published'' group by 1 order by 2 desc',
      dimension
    );
  end if;
end
$$;

create or replace function public.archive_compare(
  p_account uuid,
  p_from date default null,
  p_to date default null,
  p_category text default null
)
returns jsonb
language sql stable security invoker
set search_path = pg_catalog, public, pg_temp
as $$
  with filtered as (
    select * from public.archive_posts
    where publication_status = 'Published'
      and account_id = p_account
      and (p_from is null or published_at >= p_from)
      and (p_to is null or published_at < p_to + 1)
      and (p_category is null or primary_category = p_category)
  ),
  cats as (
    select coalesce(jsonb_agg(jsonb_build_object('label',primary_category,'value',n) order by n desc),'[]') value
    from (select primary_category,count(*) n from filtered group by 1 order by 2 desc limit 10) x
  ),
  keys as (
    select coalesce(jsonb_agg(jsonb_build_object('label',keyword,'value',n) order by n desc),'[]') value
    from (select keyword,count(*) n from filtered cross join lateral unnest(keywords) keyword group by 1 order by 2 desc limit 10) x
  ),
  freq as (
    select coalesce(jsonb_agg(jsonb_build_object('label',bucket,'value',n) order by bucket),'[]') value
    from (select to_char(date_trunc('month',published_at),'YYYY-MM') bucket,count(*) n from filtered group by 1) x
  )
  select jsonb_build_object(
    'total',count(*),
    'originals',count(*) filter(where coalesce(post_type,'Original')='Original'),
    'replies',count(*) filter(where post_type='Reply'),
    'quotes',count(*) filter(where post_type='Quote'),
    'media',count(*) filter(where media_type is not null and media_type <> 'Text'),
    'claims',count(*) filter(where contains_claim),
    'categories',(select value from cats),
    'keywords',(select value from keys),
    'frequency',(select value from freq)
  ) from filtered
$$;

create or replace function public.submit_archive_correction(
  p_post_id uuid,
  p_type text,
  p_details text,
  p_email text default null
)
returns uuid
language plpgsql security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare result uuid;
begin
  if p_type not in ('incorrect category','incorrect date','incorrect account','broken source','duplicate entry','incorrect transcription') then
    raise exception 'Invalid correction type';
  end if;
  if length(p_details) not between 10 and 5000
     or (p_email is not null and length(p_email) > 320) then
    raise exception 'Invalid correction fields';
  end if;
  if not exists (
    select 1 from public.archive_posts
    where id = p_post_id and publication_status = 'Published'
  ) then
    raise exception 'Post not found';
  end if;
  if exists (
    select 1 from public.archive_corrections
    where post_id = p_post_id and details = p_details
      and created_at > now() - interval '10 minutes'
  ) then
    raise exception 'Please wait before resubmitting';
  end if;
  insert into public.archive_corrections(post_id,correction_type,details,reporter_email,status)
  values(p_post_id,p_type,p_details,nullif(p_email,''),'submitted')
  returning id into result;
  return result;
end
$$;

revoke all on function public.archive_analytics(text) from public;
revoke all on function public.archive_distribution(text) from public;
revoke all on function public.archive_compare(uuid,date,date,text) from public;
revoke all on function public.submit_archive_correction(uuid,text,text,text) from public;
grant execute on function public.archive_analytics(text) to anon, authenticated;
grant execute on function public.archive_distribution(text) to anon, authenticated;
grant execute on function public.archive_compare(uuid,date,date,text) to anon, authenticated;
grant execute on function public.submit_archive_correction(uuid,text,text,text) to anon, authenticated;

comment on function public.is_archive_admin() is 'SECURITY DEFINER prevents archive_admins enumeration while authorising solely with auth.uid(); never user metadata.';
comment on function public.archive_analytics(text) is 'SECURITY INVOKER aggregates only rows visible through archive_posts RLS.';
comment on function public.archive_distribution(text) is 'SECURITY INVOKER aggregates only rows visible through archive_posts RLS.';
comment on function public.archive_compare(uuid,date,date,text) is 'SECURITY INVOKER compares only rows visible through archive_posts RLS.';
comment on function public.submit_archive_correction(uuid,text,text,text) is 'SECURITY DEFINER permits validated inserts without granting correction-table access to anonymous users.';
