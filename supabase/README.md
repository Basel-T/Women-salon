# Database setup (Bloom & Blush)

This salon needs **its own** Supabase project. Don't reuse the barbershop's
(nova-web) project: the bookings would mix, and "Reset demo" here would wipe
the barbershop's data.

1. Create a new project at [supabase.com](https://supabase.com).
2. In **SQL Editor → New query**, paste and **Run** each file, in this order:
   1. `schema.sql`
   2. `update-2.sql`
   3. `update-3.sql`
   4. `update-4.sql`
   5. `update-5.sql`: turns the demo into the salon (stylists, services, USD)
3. In **Project Settings → API**, copy the Project URL and the
   anon/publishable key into `src/config.ts` (`SUPABASE_URL` and
   `SUPABASE_ANON_KEY`).

Demo logins (password `12345` for staff): admin `000`, stylists `111`, `222`
and `333`, demo client `0500000000`.
