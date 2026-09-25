-- Pin search_path on the generator helpers (Supabase advisor 0011). They are not
-- reachable through the API (schema `demo` is not exposed), this is hygiene.
alter function demo.rand() set search_path = demo, public;
alter function demo.noise(float8) set search_path = demo, public;
alter function demo.sround(float8) set search_path = demo, public;
alter function demo.col(jsonb, int, float8) set search_path = demo, public;
alter function demo.mul(float8[], float8[]) set search_path = demo, public;
alter function demo.jitter(float8[], float8) set search_path = demo, public;
alter function demo.split_int(bigint, float8[]) set search_path = demo, public;
alter function demo.split_money(numeric, float8[]) set search_path = demo, public;
alter function demo.split_value(numeric, bigint[]) set search_path = demo, public;
