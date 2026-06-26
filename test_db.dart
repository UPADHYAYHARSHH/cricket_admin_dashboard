import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  final envFile = File('.env');
  final lines = await envFile.readAsLines();
  String? url;
  String? anonKey;
  
  for (var line in lines) {
    if (line.startsWith('SUPABASE_URL=')) url = line.split('=')[1];
    if (line.startsWith('SUPABASE_ANON_KEY=')) anonKey = line.split('=')[1];
  }
  
  if (url != null && anonKey != null) {
    final client = SupabaseClient(url, anonKey);
    final response = await client.from('grounds').select().limit(1);
    if (response.isNotEmpty) {
      print('Ground keys: ${response[0].keys.join(', ')}');
    } else {
      print('No grounds found');
    }
  } else {
    print('Could not read env vars');
  }
}
