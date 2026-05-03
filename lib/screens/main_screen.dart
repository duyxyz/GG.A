import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../main.dart';
import '../utils/haptics.dart';
import '../widgets/expressive_loading_indicator.dart';
import '../tabs/favorites_tab.dart';
import '../tabs/home_tab.dart';
import '../tabs/settings_tab.dart';
import '../utils/update_manager.dart';
import '../logic/viewmodels/home_view_model.dart';
import '../widgets/update_bottom_sheet.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ScrollController _nestedScrollController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<HomeTabState> _homeTabKey = GlobalKey<HomeTabState>();
  final GlobalKey<FavoritesTabState> _favoritesTabKey =
      GlobalKey<FavoritesTabState>();

  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _nestedScrollController = ScrollController();
    _tabController.addListener(() {
      if (_currentIndex != _tabController.index) {
        setState(() {
          _currentIndex = _tabController.index;
        });
        _nestedScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
        );
      }
    });

    AppDependencies.instance.homeViewModel.loadImages();
    _checkForUpdateSilent();
    cleanupUpdateFiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nestedScrollController.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdateSilent() async {
    final updateVM = AppDependencies.instance.updateViewModel;
    await updateVM.checkForUpdates();
    if (!mounted) return;
    if (updateVM.latestRelease != null) {
      _showUpdateDialog(context, updateVM.latestRelease!);
    }
  }

  void _showUpdateDialog(BuildContext context, dynamic release) {
    UpdateBottomSheet.show(context, release);
  }

  Future<void> _pickAndUploadImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    if (images.isEmpty) return;
    if (!mounted) return;

    final ValueNotifier<String> statusNotifier =
        ValueNotifier('Đang chuẩn bị...');
    final ValueNotifier<double> progressNotifier = ValueNotifier(0.0);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ExpressiveLoadingIndicator(isContained: true),
            const SizedBox(height: 16),
            ValueListenableBuilder<String>(
              valueListenable: statusNotifier,
              builder: (context, status, _) => Text(
                status,
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<double>(
              valueListenable: progressNotifier,
              builder: (context, progress, _) => LinearProgressIndicator(
                value: progress,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );

    try {
      final List<Map<String, dynamic>> processedImages = [];
      for (int i = 0; i < images.length; i++) {
        statusNotifier.value = 'Đang xử lý ${i + 1}/${images.length}...';
        progressNotifier.value = i / images.length;

        final file = images[i];
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
          'name': '${DateTime.now().millisecondsSinceEpoch}_$i.webp',
          'bytes': compressed,
          'width': imageInfo.width,
          'height': imageInfo.height,
          'path': file.path,
        });
        imageInfo.dispose();
      }

      statusNotifier.value = 'Đang gửi lên server...';
      progressNotifier.value = 1.0;

      final homeVM = AppDependencies.instance.homeViewModel;
      final bool success = await homeVM.uploadImages(processedImages);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Đã tải ảnh lên thành công!' : 'Tải ảnh thất bại.',
            ),
            backgroundColor: success
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
          ),
        );
        if (success) AppHaptics.mediumImpact();
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      statusNotifier.dispose();
      progressNotifier.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeVM = AppDependencies.instance.homeViewModel;
    final appBarTextColor = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: _tabController.index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_tabController.index != 0) {
          _tabController.animateTo(0);
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: NavigationDrawer(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 28, top: 24, bottom: 0),
              child: Text(
                'Cài đặt',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SettingsTab(isSelected: true),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: NestedScrollView(
            controller: _nestedScrollController,
            floatHeaderSlivers: true,
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                    context,
                  ),
                  sliver: SliverPersistentHeader(
                    pinned: true,
                    delegate: _MainAppBarDelegate(
                      paddingTop: 0.0,
                      expandedHeight: 92.0,
                      appBarTextColor: appBarTextColor,
                      forceElevated: innerBoxIsScrolled,
                      onMenuPressed: () =>
                          _scaffoldKey.currentState?.openDrawer(),
                      onAddPressed: _pickAndUploadImages,
                      onTitleTap: () {
                        _nestedScrollController.animateTo(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutQuart,
                        );
                        if (_currentIndex == 0) {
                          _homeTabKey.currentState?.scrollToTop();
                        } else {
                          _favoritesTabKey.currentState?.scrollToTop();
                        }
                      },
                      tabBar: TabBar(
                        controller: _tabController,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelColor: appBarTextColor,
                        unselectedLabelColor: Theme.of(
                          context,
                        ).colorScheme.onSurfaceVariant,
                        indicatorColor: appBarTextColor,
                        dividerColor: Colors.transparent,
                        tabs: const [
                          Tab(text: "Trang chủ"),
                          Tab(text: "Yêu thích"),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                HomeTab(key: _homeTabKey, viewModel: homeVM),
                FavoritesTab(key: _favoritesTabKey, viewModel: homeVM),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MainAppBarDelegate extends SliverPersistentHeaderDelegate {
  static const double _titleRowHeight = 44.0;
  static const double _tabBarHeight = 48.0;

  final double paddingTop;
  final double expandedHeight;
  final Color appBarTextColor;
  final bool forceElevated;
  final Widget tabBar;
  final VoidCallback onMenuPressed;
  final VoidCallback onAddPressed;
  final VoidCallback onTitleTap;

  _MainAppBarDelegate({
    required this.paddingTop,
    required this.expandedHeight,
    required this.appBarTextColor,
    required this.forceElevated,
    required this.tabBar,
    required this.onMenuPressed,
    required this.onAddPressed,
    required this.onTitleTap,
  });

  @override
  double get maxExtent => paddingTop + expandedHeight;

  @override
  double get minExtent => paddingTop + _tabBarHeight;

  @override
  bool shouldRebuild(covariant _MainAppBarDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        paddingTop != oldDelegate.paddingTop ||
        appBarTextColor != oldDelegate.appBarTextColor ||
        forceElevated != oldDelegate.forceElevated ||
        tabBar != oldDelegate.tabBar;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double currentHeight = maxExtent - shrinkOffset;
    final double currentFlexHeight = currentHeight - minExtent;
    final double factor = (currentFlexHeight / _titleRowHeight).clamp(0.0, 1.0);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: forceElevated || overlapsContent ? 2.0 : 0.0,
      surfaceTintColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Tầng 1: Title row
          if (factor > 0)
            Positioned(
              top: paddingTop - ((1.0 - factor) * _titleRowHeight),
              left: 0,
              right: 0,
              height: _titleRowHeight,
              child: Opacity(
                opacity: factor,
                child: NavigationToolbar(
                  leading: IconButton(
                    icon: Icon(Icons.menu_rounded, color: appBarTextColor),
                    onPressed: onMenuPressed,
                  ),
                  middle: GestureDetector(
                    onTap: onTitleTap,
                    child: Text(
                      'GG',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: appBarTextColor,
                      ),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.add_rounded, color: appBarTextColor),
                    onPressed: onAddPressed,
                  ),
                ),
              ),
            ),
          // Tầng 2: TabBar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _tabBarHeight,
            child: tabBar,
          ),
        ],
      ),
    );
  }
}
