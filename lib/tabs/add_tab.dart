import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../logic/viewmodels/home_view_model.dart';
import '../utils/haptics.dart';
import '../widgets/error_view.dart';
import '../widgets/expressive_loading_indicator.dart';

class AddTab extends StatefulWidget {
  final HomeViewModel viewModel;
  final VoidCallback onStateChanged;

  const AddTab({
    super.key,
    required this.viewModel,
    required this.onStateChanged,
  });

  @override
  State<AddTab> createState() => AddTabState();
}

class AddTabState extends State<AddTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void scrollToTop() {
    if (!mounted) return;
    PrimaryScrollController.of(context).animateTo(
      0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutQuart,
    );
  }

  final List<XFile> _selectedImages = [];
  bool _isLocalLoading = false;
  String _uploadStatus = '';

  int get selectedImagesCount => _selectedImages.length;

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images);
      });
      widget.onStateChanged();
    }
  }

  Future<void> uploadImages() async {
    if (_selectedImages.isEmpty) return;
    setState(() {
      _isLocalLoading = true;
      _uploadStatus = 'Đang nén ảnh...';
    });
    try {
      final List<Map<String, dynamic>> processedImages = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadStatus = 'Đang xử lý ${i + 1}/${_selectedImages.length}...';
        });
        final file = _selectedImages[i];
        final bytes = await file.readAsBytes();
        final compressed = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 1080,
          minHeight: 1080,
          quality: 85,
          format: CompressFormat.webp,
        );
        final imageInfo = await decodeImageFromList(compressed);
        processedImages.add({
          'name':
              'image.webp', // Tên này sẽ được ImageRepository thay thế bằng {index}_{timestamp}.webp
          'bytes': compressed,
          'width': imageInfo.width,
          'height': imageInfo.height,
          'path': file.path,
        });
        imageInfo.dispose();
      }
      setState(() {
        _uploadStatus = 'Đang gửi lên server...';
      });
      final bool success = await widget.viewModel.uploadImages(processedImages);
      if (success && mounted) {
        AppHaptics.mediumImpact();
        clearSelection();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã tải ảnh lên thành công!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLocalLoading = false;
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
    widget.onStateChanged();
  }

  void clearSelection() {
    setState(() {
      _selectedImages.clear();
    });
    widget.onStateChanged();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (widget.viewModel.error.isNotEmpty) {
      return ErrorView(
        message: 'Lỗi nạp dữ liệu: ${widget.viewModel.error}',
        onRetry: widget.viewModel.loadImages,
        isFullScreen: false,
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Builder(
          builder: (context) => CustomScrollView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == _selectedImages.length) {
                      return InkWell(
                        onTap: pickImage,
                        borderRadius: BorderRadius.circular(16),
                        child: DottedBorder(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                          strokeWidth: 2,
                          dashPattern: const [6, 4],
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(16),
                          padding: EdgeInsets.zero,
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add_rounded,
                                size: 32,
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).dividerColor.withValues(alpha: 0.1),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(_selectedImages[index].path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 6,
                          right: 6,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }, childCount: _selectedImages.length + 1),
                ),
              ),
            ],
          ),
        ),
        if (_isLocalLoading)
          Container(
            color: Colors.black45,
            child: Center(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const ExpressiveLoadingIndicator(isContained: true),
                      const SizedBox(height: 16),
                      Text(
                        _uploadStatus,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (_selectedImages.isNotEmpty && !_isLocalLoading)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              onPressed: uploadImages,
              elevation: 4,
              tooltip: 'Tải ảnh lên',
              child: const Icon(Icons.cloud_upload_rounded),
            ),
          ),
      ],
    );
  }
}
