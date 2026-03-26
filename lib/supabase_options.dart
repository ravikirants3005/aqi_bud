// Supabase configuration file
// Replace these values with your actual Supabase project credentials
//
// To get your Supabase credentials:
// 1. Go to https://supabase.com/
// 2. Create a new project or use an existing one
// 3. Go to Project Settings > API
// 4. Copy the Project URL and anon key
//
// Until you add real credentials, the app will run using local auth fallback.

import 'package:supabase_flutter/supabase_flutter.dart' show SupabaseOptions;

class DefaultSupabaseOptions {
  static SupabaseOptions get currentPlatform {
    return web;
  }

  static const SupabaseOptions web = SupabaseOptions(
    url: 'https://ituhnibxoputoodyefgv.supabase.co',
    anonKey: 'sb_publishable_pJIHGt7J6wxhgf-PlIwLsg_dbIOJjP-',
  );

  static const SupabaseOptions android = SupabaseOptions(
    url: 'https://ituhnibxoputoodyefgv.supabase.co',
    anonKey: 'sb_publishable_pJIHGt7J6wxhgf-PlIwLsg_dbIOJjP-',
  );
}
