class AppEnvironment {
  static const String defaultSupabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cxrlptsngvrqxyahahyd.supabase.co',
  );
  static const String defaultSupabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_6MZMaFJ4oVr7Dt3xQE8MOQ_H0BbuZ5Q',
  );
}
