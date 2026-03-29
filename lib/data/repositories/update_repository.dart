import 'package:device_info_plus/device_info_plus.dart';
import '../models/app_release.dart';
import '../services/github_api_service.dart';

class UpdateRepository {
  final GithubApiService _githubApi;

  UpdateRepository(this._githubApi);

  Future<AppRelease> getLatestRelease() async {
    final rawRelease = await _githubApi.fetchLatestRelease();
    return AppRelease.fromJson(rawRelease);
  }

  Future<AppAsset?> findBestAsset(List<AppAsset> assets) async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    final supportedAbis = androidInfo.supportedAbis;

    for (var abi in supportedAbis) {
      for (var asset in assets) {
        final name = asset.name.toLowerCase();
        if (name.contains(abi.toLowerCase()) && name.endsWith('.apk')) {
          return asset;
        }
      }
    }

    for (var asset in assets) {
      if (asset.name.endsWith('.apk')) {
        return asset;
      }
    }
    return null;
  }

  Future<void> downloadUpdate({
    required String url,
    required String savePath,
    required Function(double) onProgress,
  }) async {
    await _githubApi.downloadFile(
      url: url,
      savePath: savePath,
      onProgress: onProgress,
    );
  }
}
