-- ============================================================
-- Bloom & Blush — Update 5 (salon edition)
-- • US dollars (USD) by default — the app offers USD and ILS
-- • Salon demo: women stylists, salon services, "Bloom & Blush"
-- • reset_demo() now restores the salon demo
-- ============================================================
-- Paste this whole file into Supabase → SQL Editor → New query → Run.
-- Requires update-4.sql to have been run.
--
-- WARNING: running this file also resets the demo — it deletes every
-- booking, blocked time, activity entry and client (except the demo
-- client). Run it on a fresh project, or when you want a clean demo.
-- ============================================================

set search_path = public, extensions;

-- ---------- Settings: USD default ----------
alter table public.settings alter column currency set default 'USD';

-- ---------- The salon demo data (used by reset_demo and below) ----------
create or replace function public.apply_salon_demo()
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  -- 1. Wipe bookings, blocked time and the activity log
  delete from public.appointments where true;
  delete from public.blocked_slots where true;
  delete from public.activity_log where true;

  -- 2. Remove extra stylists and every account except the demo ones
  delete from public.stylists where id not in ('s1', 's2', 's3');
  delete from public.users where id not in ('u-admin', 'u-s1', 'u-s2', 'u-s3', 'u-demo-client');

  -- 3. Restore the demo accounts (temporary numbers first, so swaps can't clash)
  update public.users set mobile_number = 'tmp-' || id
    where id in ('u-admin', 'u-s1', 'u-s2', 'u-s3', 'u-demo-client');
  update public.stylists set mobile_number = 'tmp-' || id where id in ('s1', 's2', 's3');

  insert into public.users (id, full_name, mobile_number, role) values
    ('u-admin',       'Salon Admin', '000',        'admin'),
    ('u-s1',          'Sofia Reyes', '111',        'stylist'),
    ('u-s2',          'Lina Haddad', '222',        'stylist'),
    ('u-s3',          'Maya Cohen',  '333',        'stylist'),
    ('u-demo-client', 'Demo Client', '0500000000', 'client')
  on conflict (id) do update
    set full_name = excluded.full_name, mobile_number = excluded.mobile_number, role = excluded.role;

  -- Stylists keep any photo the admin uploaded
  insert into public.stylists (id, name, mobile_number, title, bio, sort, active) values
    ('s1', 'Sofia Reyes', '111', 'Senior Stylist',       'Twelve years of cuts, blow-outs and effortless everyday styles.', 1, true),
    ('s2', 'Lina Haddad', '222', 'Color Specialist',     'Balayage, soft highlights and glossy, healthy color.', 2, true),
    ('s3', 'Maya Cohen',  '333', 'Nails & Brows Artist', 'Gel manicures, brow shaping and lash lifts.', 3, true)
  on conflict (id) do update
    set name = excluded.name, mobile_number = excluded.mobile_number, title = excluded.title,
        bio = excluded.bio, sort = excluded.sort, active = true;

  -- Staff passwords back to 12345
  insert into public.staff_credentials (user_id, password_hash, updated_at)
  select v.id, crypt('12345', gen_salt('bf')), now()
  from (values ('u-admin'), ('u-s1'), ('u-s2'), ('u-s3')) as v(id)
  on conflict (user_id) do update set password_hash = excluded.password_hash, updated_at = now();

  -- 4. Restore the service menu
  delete from public.services where true;
  insert into public.services (id, name, description, price, duration_min, icon, active, sort) values
    ('svc-cut',      'Cut & Blow-dry',       'Wash, precision cut and a smooth blow-dry finish',     55,  60, '✂️', true, 1),
    ('svc-blowout',  'Blow-out & Styling',   'Wash and a bouncy blow-out or soft waves',             35,  45, '💨', true, 2),
    ('svc-color',    'Root Color',           'Root touch-up with gloss and blow-dry',                75,  90, '🎨', true, 3),
    ('svc-balayage', 'Balayage',             'Hand-painted, sun-kissed color with toner',           160, 150, '✨', true, 4),
    ('svc-mani',     'Gel Manicure',         'Shaping, cuticle care and long-lasting gel polish',    35,  45, '💅', true, 5),
    ('svc-brows',    'Brow Shape & Tint',    'Brow mapping, wax and tint',                           25,  30, '🌸', true, 6),
    ('svc-bridal',   'Bridal Hair & Makeup', 'Bridal styling and full makeup for your big day',     220, 120, '👰', true, 7);

  -- 5. Restore salon settings and opening hours
  insert into public.settings (id) values ('shop') on conflict (id) do nothing;
  update public.settings set
    shop_name = 'Bloom & Blush',
    tagline = 'Hair & Beauty Salon',
    address = '12 Market Square',
    phone = '',
    currency = 'USD',
    privacy_contact = '',
    hours = '{
      "0": {"open": "10:00", "close": "20:00"},
      "1": {"open": "10:00", "close": "20:00"},
      "2": {"open": "10:00", "close": "20:00"},
      "3": {"open": "10:00", "close": "20:00"},
      "4": {"open": "10:00", "close": "20:00"},
      "5": {"open": "10:00", "close": "20:00"},
      "6": {"open": "10:00", "close": "20:00"}
    }'::jsonb,
    slot_interval = 15,
    booking_window_days = 30,
    min_notice_min = 0,
    auto_confirm = false,
    max_upcoming = 2,
    updated_at = now()
  where id = 'shop';

  insert into public.activity_log (type, message, params, actor_name, actor_role)
  values ('demo_reset', 'Demo data was reset', '{}'::jsonb, 'System', 'system');
end $$;

-- Only reset_demo() may call it — never the app directly
revoke all on function public.apply_salon_demo() from public, anon, authenticated;

-- ---------- Reset demo (admin only) ----------
create or replace function public.reset_demo(p_token text)
returns void
language plpgsql
security definer
set search_path = public, extensions
as $$
begin
  -- Only a signed-in admin may reset
  if not exists (
    select 1
    from public.staff_sessions s
    join public.users u on u.id = s.user_id
    where s.token = p_token
      and u.role = 'admin'
      and s.created_at > now() - interval '90 days'
  ) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;

  perform public.apply_salon_demo();
end $$;

revoke all on function public.reset_demo(text) from public;
grant execute on function public.reset_demo(text) to anon, authenticated;

-- ---------- Turn this database into the salon demo now ----------
select public.apply_salon_demo();
