-- The RLS event-trigger helper must run only through its event trigger.
-- It is not a public Data API endpoint.
revoke all on function public.rls_auto_enable() from public;
revoke execute on function public.rls_auto_enable() from anon, authenticated;
comment on function public.rls_auto_enable() is 'Event-trigger helper only; direct Data API execution is prohibited.';
