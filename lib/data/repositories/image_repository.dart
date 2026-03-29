import '../models/gallery_image.dart';
import '../services/github_api_service.dart';
import '../services/supabase_api_service.dart';
import 'dart:typed_data';

class ImageRepository {
  final GithubApiService _githubApi;
  final SupabaseApiService _supabaseApi;

  ImageRepository(this._githubApi, this._supabaseApi);

  Future<List<GalleryImage>> getImages() async {
    // 1. Fetch metadata from Supabase
    final metadataList = await _supabaseApi.fetchImageMetadata();
    final aspectRatios = {
      for (var item in metadataList)
        item['image_index'] as int: (item['aspect_ratio'] as num).toDouble(),
    };

    // 2. Fetch raw images from GitHub
    final rawFiles = await _githubApi.fetchRawImages();

    // 3. Map and Sort
    final images = rawFiles
        .where((file) => file['name'].toString().endsWith('.webp'))
        .map((file) {
      final nameStr = file['name'].toString();
      final baseName = nameStr.replaceAll('.webp', '');
      final indexString = baseName.split('_').first;
      int index = int.tryParse(indexString) ?? 0;
      
      return GalleryImage.fromGithubJson(
        file,
        aspectRatio: aspectRatios[index] ?? 1.0,
      );
    }).toList();

    images.sort((a, b) => b.index.compareTo(a.index));
    return images;
  }

  Future<void> uploadImage(String filename, Uint8List bytes, int width, int height) async {
    // 1. Reserve index in Supabase
    final index = await _supabaseApi.reserveNextImageIndex();
    final indexedFilename = '${index}_$filename';

    // 2. Upload to GitHub
    await _githubApi.uploadImage(indexedFilename, bytes);

    // 3. Upsert metadata to Supabase
    await _supabaseApi.upsertImageMetadata(
      index: index,
      width: width,
      height: height,
    );
  }

  Future<void> deleteImage(GalleryImage image) async {
    // 1. Delete from GitHub
    await _githubApi.deleteImage(image.path, image.sha);

    // 2. Delete metadata from Supabase
    await _supabaseApi.deleteImageMetadata(image.index);
  }

  Future<void> bulkUpsertMetadata(List<Map<String, dynamic>> data) async {
    await _supabaseApi.bulkUpsertImageMetadata(data);
  }

  Stream<Map<int, double>> watchMetadata() {
    return _supabaseApi.getMetadataStream().map((metadata) {
      return {
        for (final item in metadata)
          item['image_index'] as int: (item['aspect_ratio'] as num).toDouble(),
      };
    });
  }
}
