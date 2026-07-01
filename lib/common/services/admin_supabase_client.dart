import 'package:supabase_flutter/supabase_flutter.dart';

/// A Supabase client initialized with the service role key.
/// This bypasses Row Level Security and should only be used in the admin
/// dashboard for privileged write operations (e.g. upserting app_config).
class AdminSupabaseClient {
  AdminSupabaseClient._();

  static SupabaseClient? _client;

  static SupabaseClient get client {
    assert(_client != null, 'AdminSupabaseClient.init() must be called before use.');
    return _client!;
  }

  static void init(String url, String serviceRoleKey) {
    _client = SupabaseClient(url, serviceRoleKey);
  }
}
