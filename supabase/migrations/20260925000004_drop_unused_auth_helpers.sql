-- The public demo has no per-user scoping, so the production app_users helpers
-- (SECURITY DEFINER, callable by anon) are unused attack surface. Drop them.
drop function public.current_user_agency_id();
drop function public.current_user_client_id();
drop function public.current_user_role();
