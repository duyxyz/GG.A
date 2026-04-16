import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseApiService {
  final SupabaseClient _client;

  SupabaseApiService(this._client);

  Future<List<Map<String, dynamic>>> fetchImageMetadata() async {
    final data = await _client
        .from('images')
        .select()
        .order('image_index', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  Future<void> upsertImageMetadata({
    required int index,
    required String name,
    required String sha,
    required int size,
    required int width,
    required int height,
  }) async {
    await _client.from('images').upsert({
      'image_index': index,
      'name': name,
      'sha': sha,
      'size': size,
      'width': width,
      'height': height,
      'aspect_ratio': width / height,
    });
  }

  Future<void> deleteImageMetadata(int index) async {
    await _client.from('images').delete().eq('image_index', index);
  }

  Future<void> bulkUpsertImageMetadata(
    List<Map<String, dynamic>> dataList,
  ) async {
    if (dataList.isEmpty) return;
    await _client.from('images').upsert(dataList);
  }

  Future<int> reserveNextImageIndex() async {
    // 1. Lấy tất cả các index hiện có, sắp xếp tăng dần
    final data = await _client
        .from('images')
        .select('image_index')
        .order('image_index', ascending: true);

    final List<int> indices = (data as List)
        .map((e) => e['image_index'] as int)
        .toList();

    // 2. Tìm số nhỏ nhất còn thiếu (bắt đầu từ 1)
    int targetIndex = 1;
    for (int index in indices) {
      if (index == targetIndex) {
        targetIndex++;
      } else if (index > targetIndex) {
        // Tìm thấy số bị trống
        return targetIndex;
      }
    }

    // Nếu không có số nào trống thì trả về số kế tiếp sau số lớn nhất
    return targetIndex;
  }

  Stream<List<Map<String, dynamic>>> getMetadataStream() {
    return _client
        .from('images')
        .stream(primaryKey: ['image_index'])
        .order('image_index', ascending: false);
  }
}
