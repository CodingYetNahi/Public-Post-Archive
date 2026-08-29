-- Public research aggregates need no privilege escalation: archive_posts RLS
-- already exposes only published rows to anonymous and ordinary signed-in users.
alter function public.archive_analytics(text) security invoker;
alter function public.archive_distribution(text) security invoker;
alter function public.archive_compare(uuid,date,date,text) security invoker;

-- Anonymous requests do not use the administrator helper in any policy.
revoke execute on function public.is_archive_admin() from anon;

comment on function public.archive_analytics(text) is 'SECURITY INVOKER aggregates only rows visible through archive_posts RLS.';
comment on function public.archive_distribution(text) is 'SECURITY INVOKER aggregates only rows visible through archive_posts RLS.';
comment on function public.archive_compare(uuid,date,date,text) is 'SECURITY INVOKER compares only rows visible through archive_posts RLS.';
