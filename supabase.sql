-- Iscrizioni al torneo di Mortal Kombat 11 (sabato 21 novembre).
-- Incolla tutto nel SQL Editor del progetto Supabase e premi Run.

create table public.iscrizioni (
  id bigint generated always as identity primary key,
  created_at timestamptz not null default now(),
  nome text not null check (char_length(btrim(nome)) between 1 and 40),
  tag text check (char_length(tag) <= 20),
  livello text not null check (livello in ('Principiante', 'Me la cavo', 'Esperto')),
  main text check (char_length(main) <= 30),
  -- quello che compare sul tabellone pubblico: nome da combattente, altrimenti solo il nome di battesimo
  display text generated always as (coalesce(nullif(btrim(tag), ''), split_part(btrim(nome), ' ', 1))) stored
);

alter table public.iscrizioni enable row level security;
create policy "chiunque si iscrive" on public.iscrizioni for insert to anon with check (true);
create policy "chiunque legge il tabellone" on public.iscrizioni for select to anon using (true);

-- con la chiave pubblica si possono solo aggiungere iscrizioni e leggere le colonne del tabellone:
-- niente nome completo, niente modifiche, niente cancellazioni. Tutto il resto lo vedi dalla dashboard.
revoke all on public.iscrizioni from anon, authenticated;
grant insert (nome, tag, livello, main) on public.iscrizioni to anon;
grant select (id, created_at, display, livello, main) on public.iscrizioni to anon;
