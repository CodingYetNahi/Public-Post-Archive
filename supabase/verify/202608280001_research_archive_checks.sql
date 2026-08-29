-- Read-only pre/post migration checks. Run in Supabase SQL Editor and inspect every result.
select table_name from information_schema.tables where table_schema='public' and table_name like 'archive_%' order by 1;
select table_name,column_name,data_type,is_nullable from information_schema.columns where table_schema='public' and table_name like 'archive_%' order by 1,ordinal_position;
select tablename,indexname,indexdef from pg_indexes where schemaname='public' and tablename like 'archive_%' order by 1,2;
select schemaname,tablename,policyname,roles,cmd,qual,with_check from pg_policies where schemaname='public' and tablename like 'archive_%' order by 2,3;
select table_name,grantee,privilege_type from information_schema.role_table_grants where table_schema='public' and table_name like 'archive_%' and grantee in ('anon','authenticated') order by 1,2,3;
select p.proname,pg_get_function_identity_arguments(p.oid) arguments,p.prosecdef security_definer,has_function_privilege('anon',p.oid,'execute') anon_execute,has_function_privilege('authenticated',p.oid,'execute') authenticated_execute from pg_proc p join pg_namespace n on n.oid=p.pronamespace where n.nspname='public' and p.proname like '%archive%' order by 1,2;
select c.relname,c.relrowsecurity,c.relforcerowsecurity from pg_class c join pg_namespace n on n.oid=c.relnamespace where n.nspname='public' and c.relkind='r' and c.relname like 'archive_%' order by 1;
select 'archive_accounts' table_name,count(*) row_count from public.archive_accounts union all select 'archive_posts',count(*) from public.archive_posts;
