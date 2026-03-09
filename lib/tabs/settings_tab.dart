import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../main.dart';
import '../services/github_service.dart';
import '../utils/haptics.dart';
import '../utils/update_manager.dart';
import '../utils/migrate_to_supabase.dart';
import '../services/supabase_service.dart';

class SettingsTab extends StatefulWidget {
  final bool isSelected;
  const SettingsTab({super.key, this.isSelected = false});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  String _cacheSize = 'Đang tính...';

  @override
  void initState() {
    super.initState();
    _calculateCacheSize();
  }

  @override
  void didUpdateWidget(covariant SettingsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _calculateCacheSize();
    }
  }

  Future<void> _calculateCacheSize() async {
    try {
      int totalSize = 0;
      final dirs = [
        await getTemporaryDirectory(),
        await getApplicationSupportDirectory(),
      ];

      for (final dir in dirs) {
        if (dir.existsSync()) {
          try {
            await for (final file in dir.list(recursive: true, followLinks: false)) {
              if (file is File) {
                try {
                  totalSize += await file.length();
                } catch (_) {}
              }
            }
          } catch (_) {}
        }
      }
      
      if (mounted) {
        setState(() {
          _cacheSize = '${(totalSize / (1024 * 1024)).toStringAsFixed(1)} MB';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cacheSize = '0.0 MB';
        });
      }
    }
  }

  Future<void> _manualUpdateCheck(BuildContext context, String currentVersion) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đang kiểm tra bản cập nhật mới...'),
        duration: Duration(seconds: 1),
      ),
    );

    final result = await GithubService.checkUpdate();
    
    if (!result['success']) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể kiểm tra: ${result['error']}')),
      );
      return;
    }

    final updateData = result['data'];
    final latestVersion = updateData['tag_name'].toString().replaceAll('v', '');
    
    if (!mounted) return;

    if (latestVersion != currentVersion) {
      _showUpdateDialog(context, updateData);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn đang sử dụng phiên bản mới nhất!')),
      );
    }
  }

  void _showUpdateDialog(BuildContext context, Map<String, dynamic> updateData) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('🎉 Có bản cập nhật mới!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Phiên bản mới: ${updateData['tag_name']}'),
            const SizedBox(height: 8),
            Text(updateData['body'] ?? 'Cập nhật tính năng mới và sửa lỗi.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Để sau'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              startUpdateProcess(context, updateData);
            },
            child: const Text('Cập nhật ngay'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const ClampingScrollPhysics(),
      children: [
        const Divider(),
        ValueListenableBuilder<String>(
          valueListenable: GithubService.apiRemaining,
          builder: (context, remaining, _) {
            return Column(
              children: [
                ListTile(
                  title: const Text(
                    'Giới hạn API',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  trailing: Text(
                    '$remaining/5000',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    final version = snapshot.hasData ? snapshot.data!.version : '...';
                    return ListTile(
                      title: const Text('Phiên bản hiện tại'),
                      subtitle: const Text('Nhấn để kiểm tra cập nhật'),
                      trailing: Text(
                        'v$version',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      onTap: () => _manualUpdateCheck(context, version),
                    );
                  },
                ),
              ],
            );
          },
        ),
        const Divider(),
        ValueListenableBuilder<bool>(
          valueListenable: MyApp.hapticNotifier,
          builder: (context, hapticsEnabled, _) {
            return SwitchListTile(
              title: const Text('Rung phản hồi'),
              subtitle: const Text('Phản hồi xúc giác khi chạm, vuốt'),
              secondary: const Icon(Icons.vibration),
              value: hapticsEnabled,
              onChanged: (bool value) async {
                MyApp.hapticNotifier.value = value;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('hapticsEnabled', value);
                if (value) {
                  AppHaptics.lightImpact();
                }
              },
            );
          },
        ),
        ValueListenableBuilder<bool>(
          valueListenable: MyApp.lockNotifier,
          builder: (context, lockEnabled, _) {
            return SwitchListTile(
              title: const Text('Khoá ứng dụng'),
              subtitle: const Text('Sử dụng vân tay hoặc khuôn mặt'),
              secondary: const Icon(Icons.security),
              value: lockEnabled,
              onChanged: (bool value) async {
                MyApp.lockNotifier.value = value;
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('lockEnabled', value);
                if (value) {
                  AppHaptics.lightImpact();
                }
              },
            );
          },
        ),
        const Divider(),
        ValueListenableBuilder<int>(
          valueListenable: MyApp.gridColumnsNotifier,
          builder: (context, gridCols, _) {
            return ListTile(
              title: const Text('Số lượng cột lưới ảnh'),
              trailing: SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<int>(value: 1, label: Text('1')),
                  ButtonSegment<int>(value: 2, label: Text('2')),
                  ButtonSegment<int>(value: 3, label: Text('3')),
                ],
                selected: {gridCols},
                onSelectionChanged: (Set<int> newSelection) async {
                  final newValue = newSelection.first;
                  MyApp.gridColumnsNotifier.value = newValue;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('gridColumns', newValue);
                  AppHaptics.selectionClick();
                },
              ),
            );
          },
        ),
        const Divider(),
        ValueListenableBuilder<ThemeMode>(
          valueListenable: MyApp.themeNotifier,
          builder: (context, currentMode, _) {
            return ListTile(
              title: const Text('Chế độ sáng/tối'),
              trailing: SegmentedButton<ThemeMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    icon: Icon(Icons.brightness_auto),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    icon: Icon(Icons.wb_sunny_rounded),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    icon: Icon(Icons.nightlight_round),
                  ),
                ],
                selected: {currentMode},
                onSelectionChanged: (Set<ThemeMode> newSelection) async {
                  final newValue = newSelection.first;
                  MyApp.themeNotifier.value = newValue;
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setInt('themeMode', newValue.index);
                  AppHaptics.selectionClick();
                },
              ),
            );
          },
        ),
        const Divider(),
        ValueListenableBuilder<Color>(
          valueListenable: MyApp.themeColorNotifier,
          builder: (context, currentColor, _) {
            final List<Color> extendedColors = [
              Colors.red, Colors.redAccent, Colors.pink, Colors.pinkAccent,
              Colors.purple, Colors.deepPurple, Colors.indigo, Colors.blue,
              Colors.lightBlue, Colors.cyan, Colors.teal, Colors.green,
              Colors.lightGreen, Colors.lime, Colors.yellow, Colors.amber,
              Colors.orange, Colors.deepOrange, Colors.brown, Colors.grey,
              Colors.blueGrey, const Color(0xFF1E88E5), const Color(0xFF00897B), const Color(0xFFD81B60),
            ];

            return ListTile(
              title: const Text('Chọn màu tùy chỉnh'),
              subtitle: const Text('Nhấn để mở bảng màu'),
              trailing: Material(
                color: currentColor,
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: const CircleBorder(),
                child: const SizedBox(
                  width: 36,
                  height: 36,
                ),
              ),
              onTap: () {
                AppHaptics.selectionClick();
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Chọn màu chủ đạo'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const ClampingScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: extendedColors.length,
                          itemBuilder: (context, index) {
                            final color = extendedColors[index];
                            final isSelected = currentColor.value == color.value;
                            return GestureDetector(
                              onTap: () async {
                                AppHaptics.selectionClick();
                                MyApp.themeColorNotifier.value = color;
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.setInt('themeColor', color.value);
                                if (context.mounted) Navigator.pop(context);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) : null,
                                ),
                                child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
        const Divider(),
        ListTile(
          title: const Text('Xoá bộ nhớ đệm'),
          subtitle: Text('Dung lượng đang dùng: $_cacheSize'),
          leading: const Icon(Icons.delete_outline),
          onTap: () async {
            AppHaptics.mediumImpact();
            await DefaultCacheManager().emptyCache();
            try {
              final dirs = [
                await getTemporaryDirectory(),
                await getApplicationSupportDirectory(),
              ];
              for (final dir in dirs) {
                if (dir.existsSync()) {
                  final entities = dir.listSync(recursive: true, followLinks: false);
                  for (final entity in entities) {
                    if (entity is File) {
                      try {
                        await entity.delete();
                      } catch (_) {}
                    }
                  }
                }
              }
            } catch (_) {}

            await Future.delayed(const Duration(milliseconds: 400));
            await _calculateCacheSize(); 
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Đã xoá sạch bộ nhớ đệm!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Quản trị cơ sở dữ liệu',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
        ),
        ListTile(
          title: const Text('Đồng bộ ảnh cũ'),
          subtitle: const Text('Lấy dữ liệu từ GitHub và đẩy vào Supabase'),
          leading: const Icon(Icons.sync_rounded),
          onTap: () async {
            AppHaptics.mediumImpact();
            if (!SupabaseService.isInitialized) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vui lòng cấu hình Supabase trước!')),
              );
              return;
            }
            
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => const Center(child: CircularProgressIndicator()),
            );

            final result = await MigrationUtility.migrateFromGitHub();
            
            if (context.mounted) {
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Kết quả đồng bộ'),
                  content: Text(result),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            }
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
