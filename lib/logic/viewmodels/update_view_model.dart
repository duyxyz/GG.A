import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../data/models/app_release.dart';
import '../../data/repositories/update_repository.dart';
import 'package:package_info_plus/package_info_plus.dart';

class UpdateViewModel extends ChangeNotifier {
  final UpdateRepository _updateRepository;

  UpdateViewModel(this._updateRepository);

  AppRelease? _latestRelease;
  bool _isChecking = false;
  String? _error;

  AppRelease? get latestRelease => _latestRelease;
  bool get isChecking => _isChecking;
  String? get error => _error;

  Future<void> checkForUpdates() async {
    _isChecking = true;
    _error = null;
    notifyListeners();

    try {
      final release = await _updateRepository.getLatestRelease();
      final info = await PackageInfo.fromPlatform();
      final currentVersion = info.version;
      
      if (release.version != currentVersion) {
        _latestRelease = release;
      } else {
        _latestRelease = null;
      }
      _isChecking = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<AppAsset?> findBestAssetFromRelease(AppRelease release) async {
    return await _updateRepository.findBestAsset(release.assets);
  }

  void clearUpdate() {
    _latestRelease = null;
    notifyListeners();
  }
}
