// ============================================================
// config.ts — Supabase connection settings
// ============================================================
// Find both values in Supabase → Project Settings → API.
// The anon/publishable key is designed to be public (it ships to the browser).
// ============================================================

// This salon needs its own Supabase project — never reuse the barbershop's,
// or bookings mix and "Reset demo" wipes the other site. See supabase/README.md.
export const SUPABASE_URL = '';
export const SUPABASE_ANON_KEY = '';

/**
 * DEMO_MODE — true while the app is shown to salons as a demo.
 * Shows the one-tap "Try as Admin / Stylist / Client" buttons on the login
 * screen and the "Reset demo" button in Admin → Settings.
 * Set to false before a real shop uses the app.
 */
export const DEMO_MODE = true;

/** Demo accounts used by the "Try as…" buttons (see supabase/update-5.sql) */
export const DEMO_ACCOUNTS = {
  admin: { mobile: '000', password: '12345' },
  barber: { mobile: '111', password: '12345' },
  client: { mobile: '0500000000', name: 'Demo Client' },
};
