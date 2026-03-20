import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:cached_network_image/cached_network_image.dart';
import '../services/github_service.dart';
import '../services/supabase_service.dart';
import '../utils/haptics.dart';
import '../widgets/error_view.dart';
import '../widgets/pulse_skeleton.dart';

class ManageTab extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final bool isLoading;
  final String error;
  final Future<void> Function() onRefresh;

  const ManageTab({
    super.key,
    required this.images,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
  });

  @override
  State<ManageTab> createState() => _ManageTabState();
}

class _ManageTabState extends State<ManageTab> {
  // --- Upload state ---
  bool _isUploading = false;
  String _uploadStatus = "";
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedToUpload = [];

  // --- Delete state ---
  bool _isSelectionMode = false;
  bool _isDeleting = false;
  final Set<String> _selectedSha = {};

  // ========================
  //  UPLOAD (Thêm ảnh)
  // ========================

  Future<void> _pickImage() async {
    AppHaptics.lightImpact();
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      if (images.isNotEmpty) {
        setState(() {
          _selectedToUpload.addAll(images);
        });
        _showUploadSheet();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chọn ảnh: $e')),
        );
      }
    }
  }

  void _showUploadSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(
                        'Đăng ${_selectedToUpload.length} ảnh',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          setState(() => _selectedToUpload.clear());
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Grid preview
                Flexible(
                  child: GridView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _selectedToUpload.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _selectedToUpload.length) {
                        return InkWell(
                          onTap: () async {
                            try {
                              final more = await _picker.pickMultiImage();
                              if (more.isNotEmpty) {
                                setState(() => _selectedToUpload.addAll(more));
                                setSheetState(() {});
                              }
                            } catch (_) {}
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                    .outlineVariant,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child:
                                const Icon(Icons.add_a_photo_outlined, size: 28),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                File(_selectedToUpload[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                setState(() =>
                                    _selectedToUpload.removeAt(index));
                                setSheetState(() {});
                                if (_selectedToUpload.isEmpty) {
                                  Navigator.pop(ctx);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                // Upload button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _uploadImages();
                      },
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Đăng tất cả ảnh'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _uploadImages() async {
    if (_selectedToUpload.isEmpty) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận Đăng Ảnh'),
          content: Text(
            'Bạn có chắc chắn muốn đăng ${_selectedToUpload.length} bức ảnh này lên Bộ Sưu Tập chung không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Đồng ý'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = "Bắt đầu tải lên...";
    });

    try {
      List<Map<String, dynamic>> currentImages = List.from(widget.images);

      for (int i = 0; i < _selectedToUpload.length; i++) {
        final image = _selectedToUpload[i];
        setState(() {
          _uploadStatus =
              "Đang xử lý ${i + 1}/${_selectedToUpload.length}...";
        });

        final Uint8List? compressedBytes =
            await FlutterImageCompress.compressWithFile(
          image.path,
          minWidth: 1920,
          minHeight: 1920,
          quality: 80,
          format: CompressFormat.webp,
        );

        if (compressedBytes == null) continue;

        int nextIndex = 1;
        List<int> existingIndexes = currentImages
            .map<int>((img) => img['index'] as int)
            .toList()
          ..sort();

        for (int idx = 0; idx < existingIndexes.length; idx++) {
          if (existingIndexes[idx] == nextIndex) {
            nextIndex++;
          } else if (existingIndexes[idx] > nextIndex) {
            break;
          }
        }

        final filename = '$nextIndex.webp';
        await GithubService.uploadImage(filename, compressedBytes);

        try {
          final decodedImage = img.decodeImage(compressedBytes);
          if (decodedImage != null) {
            await SupabaseService.upsertImageMetadata(
              nextIndex,
              decodedImage.width,
              decodedImage.height,
            );
          }
        } catch (e) {
          debugPrint('Lỗi lưu Supabase: $e');
        }

        currentImages.add({'index': nextIndex});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tải tất cả ảnh lên thành công!')),
        );
        setState(() {
          _selectedToUpload.clear();
        });
      }
      await widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi tải lên: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // ========================
  //  DELETE (Xóa ảnh)
  // ========================

  void _exitSelectionMode() {
    AppHaptics.lightImpact();
    setState(() {
      _isSelectionMode = false;
      _selectedSha.clear();
    });
  }

  void _toggleSelection(String sha) {
    AppHaptics.selectionClick();
    setState(() {
      if (_selectedSha.contains(sha)) {
        _selectedSha.remove(sha);
        if (_selectedSha.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedSha.add(sha);
      }
    });
  }

  void _enterSelectionMode(String sha) {
    AppHaptics.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedSha.add(sha);
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedSha.isEmpty) return;

    AppHaptics.lightImpact();
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xác nhận Xóa Ảnh'),
          content: Text(
            'Bạn có chắc chắn muốn xóa vĩnh viễn ${_selectedSha.length} bức ảnh đã chọn khỏi Bộ Sưu Tập không? Hành động này không thể hoàn tác.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xóa vĩnh viễn'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);

    try {
      int successCount = 0;
      for (String sha in _selectedSha) {
        final image = widget.images.firstWhere((e) => e['sha'] == sha);
        await GithubService.deleteImage(image['path'], sha);
        if (image['index'] != null) {
          await SupabaseService.deleteImageMetadata(image['index'] as int);
        }
        successCount++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa thành công $successCount ảnh')),
        );
      }
      setState(() {
        _selectedSha.clear();
        _isSelectionMode = false;
      });
      await widget.onRefresh();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Lỗi xóa ảnh: $e')));
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  // ========================
  //  BUILD
  // ========================

  @override
  Widget build(BuildContext context) {
    if (widget.error.isNotEmpty) {
      return ErrorView(
        message: 'Lỗi nạp dữ liệu: ${widget.error}',
        onRetry: widget.onRefresh,
        isFullScreen: false,
      );
    }

    // Uploading state
    if (_isUploading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const PulseSkeleton(width: 100, height: 100),
            const SizedBox(height: 16),
            Text(_uploadStatus,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // Deleting state
    if (_isDeleting) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PulseSkeleton(width: 80, height: 80),
            SizedBox(height: 16),
            Text(
              "Đang xóa ảnh...",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      // App bar with selection mode
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                onPressed: _exitSelectionMode,
                icon: const Icon(Icons.close),
              ),
              title: Text('Đã chọn ${_selectedSha.length} ảnh'),
              actions: [
                IconButton(
                  onPressed: _deleteSelected,
                  icon: const Icon(Icons.delete_rounded),
                  tooltip: 'Xóa ảnh đã chọn',
                  color: colorScheme.error,
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // Image grid
          widget.images.isEmpty && !widget.isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.photo_library_outlined,
                          size: 80, color: colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Text(
                        'Chưa có ảnh nào',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nhấn nút + để thêm ảnh mới',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(8),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemCount: widget.images.length,
                  itemBuilder: (context, index) {
                    final image = widget.images[index];
                    final isSelected = _selectedSha.contains(image['sha']);

                    return GestureDetector(
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(image['sha']);
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _enterSelectionMode(image['sha']);
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: isSelected
                              ? Border.all(color: colorScheme.error, width: 3)
                              : null,
                        ),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                  isSelected ? 7 : 10),
                              child: CachedNetworkImage(
                                imageUrl: image['download_url'],
                                fit: BoxFit.cover,
                                memCacheWidth:
                                    (MediaQuery.of(context).size.width * 0.4)
                                        .round(),
                                placeholder: (context, url) =>
                                    const PulseSkeleton(
                                  borderRadius: BorderRadius.all(
                                      Radius.circular(10)),
                                ),
                                errorWidget: (context, url, error) =>
                                    Container(
                                  color: colorScheme.errorContainer,
                                  child: const Icon(
                                    Icons.image_not_supported_rounded,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                            if (isSelected)
                              Container(
                                decoration: BoxDecoration(
                                  color: colorScheme.error
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(7),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                    size: 32,
                                  ),
                                ),
                              ),
                            if (_isSelectionMode && !isSelected)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white70, width: 2),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
          // Loading indicator
          if (widget.isLoading)
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(),
            ),
        ],
      ),
      // FloatingActionButton to add images (hidden in selection mode)
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton(
              onPressed: _pickImage,
              tooltip: 'Thêm ảnh',
              child: const Icon(Icons.add_a_photo_outlined),
            ),
    );
  }
}
