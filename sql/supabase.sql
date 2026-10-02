create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  description text default '',
  price numeric(12,2) not null default 0,
  old_price numeric(12,2),
  image_url text,
  offer_url text not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.products enable row level security;
drop policy if exists "public can read active products" on public.products;
create policy "public can read active products" on public.products for select using (active = true);
drop policy if exists "authenticated can read all products" on public.products;
create policy "authenticated can read all products" on public.products for select to authenticated using (true);
drop policy if exists "authenticated can insert products" on public.products;
create policy "authenticated can insert products" on public.products for insert to authenticated with check (true);
drop policy if exists "authenticated can update products" on public.products;
create policy "authenticated can update products" on public.products for update to authenticated using (true) with check (true);
drop policy if exists "authenticated can delete products" on public.products;
create policy "authenticated can delete products" on public.products for delete to authenticated using (true);

insert into storage.buckets (id, name, public) values ('product-images','product-images',true) on conflict (id) do update set public = true;
drop policy if exists "public can view product images" on storage.objects;
create policy "public can view product images" on storage.objects for select using (bucket_id = 'product-images');
drop policy if exists "authenticated can upload product images" on storage.objects;
create policy "authenticated can upload product images" on storage.objects for insert to authenticated with check (bucket_id = 'product-images');
drop policy if exists "authenticated can update product images" on storage.objects;
create policy "authenticated can update product images" on storage.objects for update to authenticated using (bucket_id = 'product-images') with check (bucket_id = 'product-images');
drop policy if exists "authenticated can delete product images" on storage.objects;
create policy "authenticated can delete product images" on storage.objects for delete to authenticated using (bucket_id = 'product-images');

create or replace function public.set_updated_at() returns trigger language plpgsql as $$ begin new.updated_at = now(); return new; end; $$;
drop trigger if exists products_updated_at on public.products;
create trigger products_updated_at before update on public.products for each row execute function public.set_updated_at();
