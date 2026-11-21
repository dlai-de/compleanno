-- Regia del torneo: lo stato (sorteggio, risultati, formato, assenti) sta qui, tutti lo leggono, lo scrive solo chi ha il token di regia.
-- Incolla tutto nel SQL Editor del progetto Supabase e premi Run. Si può rieseguire.
-- L'ultima query restituisce il link di regia: il token non sta nella repo, tienilo per te.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
create table if not exists private.regia_token (token text primary key);

create table if not exists public.regia (
  id int primary key default 1 check (id = 1),
  stato jsonb not null default '{}',
  aggiornato timestamptz not null default now()
);
insert into public.regia default values on conflict do nothing;
alter table public.regia enable row level security;
drop policy if exists "tutti guardano il torneo" on public.regia;
create policy "tutti guardano il torneo" on public.regia for select to anon using (true);
revoke all on public.regia from anon, authenticated;
grant select on public.regia to anon;

create or replace function public.regia_entra(token text) returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from private.regia_token t where t.token = regia_entra.token)
$$;

create or replace function public.regia_salva(token text, nuovo_stato jsonb) returns timestamptz
language plpgsql security definer set search_path = '' as $$
declare t timestamptz;
begin
  if not public.regia_entra(token) then raise exception 'token di regia non valido'; end if;
  update public.regia set stato = nuovo_stato, aggiornato = now() where id = 1 returning aggiornato into t;
  return t;
end $$;

-- rinomina (diventa il nome sul tabellone), cambia livello o elimina un iscritto
create or replace function public.regia_giocatore(token text, giocatore bigint, nuovo_nome text default null, nuovo_livello text default null, elimina boolean default false) returns void
language plpgsql security definer set search_path = '' as $$
begin
  if not public.regia_entra(token) then raise exception 'token di regia non valido'; end if;
  if elimina then
    delete from public.iscrizioni where id = giocatore;
  else
    update public.iscrizioni set tag = coalesce(nullif(btrim(nuovo_nome), ''), tag), livello = coalesce(nuovo_livello, livello) where id = giocatore;
  end if;
end $$;

revoke all on function public.regia_entra(text), public.regia_salva(text, jsonb), public.regia_giocatore(text, bigint, text, text, boolean) from public;
grant execute on function public.regia_entra(text), public.regia_salva(text, jsonb), public.regia_giocatore(text, bigint, text, text, boolean) to anon;

insert into private.regia_token select replace(gen_random_uuid()::text, '-', '') where not exists (select 1 from private.regia_token);
select 'https://dlai-de.github.io/compleanno/torneo.html#' || token as link_regia from private.regia_token;
