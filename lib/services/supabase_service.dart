import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://pplwdupvhmypmkjxcxpr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBwbHdkdXB2aG15cG1ranhjeHByIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMwNTc3NzEsImV4cCI6MjA4ODYzMzc3MX0.UikH-oZ3vC72RL8PPIzgUr6N12Mq6Pk8aGLqri7PGiM';
  static bool _initialized = false;

  static SupabaseClient get client {
    if (!_initialized) {
      throw Exception('Supabase has not been initialized. Check your environment variables.');
    }
    return Supabase.instance.client;
  }

  static bool get isInitialized => _initialized;

  static Future<void> initialize() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      print('Supabase credentials missing. Supabase functionality will be disabled.');
      return;
    }
    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
      );
      _initialized = true;
    } catch (e) {
      print('Failed to initialize Supabase: $e');
    }
  }

  static Future<void> deleteImageMetadata(int index) async {
    if (!_initialized) return;
    try {
      await client.from('images').delete().eq('image_index', index);
    } catch (e) {
      print('Error deleting metadata from Supabase: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> fetchImageMetadata() async {
    if (!_initialized) return [];
    try {
      final data = await client
          .from('images')
          .select()
          .order('image_index', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('Error fetching metadata from Supabase: $e');
      return [];
    }
  }

  static Future<void> upsertImageMetadata(int index, int width, int height) async {
    if (!_initialized) return;
    try {
      await client.from('images').upsert({
        'image_index': index,
        'width': width,
        'height': height,
        'aspect_ratio': width / height,
      });
    } catch (e) {
      print('Error upserting metadata to Supabase: $e');
    }
  }

  static Future<int> reserveNextImageIndex() async {
    if (!_initialized) {
      throw Exception('Supabase has not been initialized.');
    }
    final result = await client.rpc('reserve_next_image_index');
    if (result is int) return result;
    if (result is num) return result.toInt();
    throw Exception('Invalid index returned from Supabase RPC.');
  }

  static Future<void> bulkUpsertImageMetadata(List<Map<String, dynamic>> dataList) async {
    if (!_initialized || dataList.isEmpty) return;
    try {
      await client.from('images').upsert(dataList);
    } catch (e) {
      print('Error bulk upserting to Supabase: $e');
      rethrow;
    }
  }

  static Stream<List<Map<String, dynamic>>> metadataStream() {
    if (!_initialized) {
      return Stream.value([]);
    }
    return client
        .from('images')
        .stream(primaryKey: ['image_index'])
        .order('image_index', ascending: false);
  }
}
