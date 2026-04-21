import 'dart:async';
import 'package:flutter/material.dart';
import '../main.dart';
import '../tabs/add_tab.dart';
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
      }
    });

    // Initialize data through ViewModels
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
        drawer: SafeArea(
          child: Drawer(
            child: Scaffold(
              appBar: AppBar(
                title: const Text(
                  'Cài đặt',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                automaticallyImplyLeading: false,
              ),
              body: const SettingsTab(isSelected: true),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (_) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.85,
                child: Scaffold(
                  appBar: AppBar(
                    title: const Text(
                      'Thêm Ảnh',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    leading: const CloseButton(),
                  ),
                  body: AddTab(viewModel: homeVM, onStateChanged: () {}),
                ),
              ),
            );
          },
          child: const Icon(Icons.add_rounded),
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
                      homeVM: homeVM,
                      forceElevated: innerBoxIsScrolled,
                      onMenuPressed: () =>
                          _scaffoldKey.currentState?.openDrawer(),
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
  final double paddingTop;
  final double expandedHeight;
  final Color appBarTextColor;
  final HomeViewModel homeVM;
  final bool forceElevated;
  final Widget tabBar;
  final VoidCallback onMenuPressed;

  _MainAppBarDelegate({
    required this.paddingTop,
    required this.expandedHeight,
    required this.appBarTextColor,
    required this.homeVM,
    required this.forceElevated,
    required this.tabBar,
    required this.onMenuPressed,
  });

  @override
  double get maxExtent => paddingTop + expandedHeight;

  @override
  double get minExtent => paddingTop + 48.0;

  @override
  bool shouldRebuild(covariant _MainAppBarDelegate oldDelegate) {
    return expandedHeight != oldDelegate.expandedHeight ||
        paddingTop != oldDelegate.paddingTop ||
        appBarTextColor != oldDelegate.appBarTextColor ||
        homeVM != oldDelegate.homeVM ||
        forceElevated != oldDelegate.forceElevated;
  }

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final double currentHeight = maxExtent - shrinkOffset;
    final double currentFlexHeight = currentHeight - minExtent;
    final double factor = (currentFlexHeight / 44.0).clamp(0.0, 1.0);

    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: forceElevated || overlapsContent ? 2.0 : 0.0,
      surfaceTintColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: paddingTop - ((1.0 - factor) * 44.0),
            left: 0,
            right: 0,
            height: 44.0,
            child: Opacity(
              opacity: factor,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.menu_rounded, color: appBarTextColor),
                      onPressed: onMenuPressed,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Gay Group',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: appBarTextColor,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: Center(
                        child: Text(
                          '${homeVM.images.length} ảnh',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: appBarTextColor,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(bottom: 0, left: 0, right: 0, height: 48.0, child: tabBar),
        ],
      ),
    );
  }
}
