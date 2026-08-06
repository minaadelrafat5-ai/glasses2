import { createClient, type SupabaseClient } from '@supabase/supabase-js';

/**
 * Singleton Supabase browser client.
 *
 * Reads public anon credentials from Vite env. The service role key is never
 * exposed to the browser — privileged operations run in edge functions only.
 */
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string | undefined;
const supabaseAnonKey = import.meta.env.VITE_SUPABASE_ANON_KEY as string | undefined;

if (!supabaseUrl || !supabaseAnonKey) {
  // Surface a clear error during development. The app is designed to degrade
  // gracefully (the service layer checks `isConfigured` before calling).
  console.warn(
    '[supabase] Missing VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY. ' +
      'Database and auth features will be unavailable until configured.',
  );
}

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseAnonKey);

export const supabase: SupabaseClient = createClient(
  supabaseUrl ?? 'http://localhost:5432',
  supabaseAnonKey ?? 'public-anon-key',
  {
    auth: {
      persistSession: true,
      autoRefreshToken: true,
      detectSessionInUrl: true,
    },
  },
);
