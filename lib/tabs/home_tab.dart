import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../logic/viewmodels/home_view_model.dart';
import '../main.dart';
import '../widgets/error_view.dart';
import '../widgets/expressive_loading_indicator.dart';
import '../widgets/image_grid_item.dart';

class HomeTab extends StatefulWidget {
  final HomeViewModel viewModel;

  const HomeTab({super.key, required this.viewModel});

  @override
  State<HomeTab> createState() => HomeTabState();
}

class HomeTabState extends State<HomeTab> with AutomaticKeepAliveClientMixin {
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final viewModel = widget.viewModel;
    final gridConfig = AppDependencies.instance.configViewModel;

    return Builder(
      builder: (context) => ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final showSkeletons = viewModel.isLoading && viewModel.images.isEmpty;

          return CustomScrollView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
              ),
              if (viewModel.error.isNotEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorView(
                    message: 'Lỗi: ${viewModel.error}',
                    onRetry: viewModel.loadImages,
                    isFullScreen: false,
                  ),
                )
              else if (showSkeletons)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: ExpressiveLoadingIndicator(isContained: true),
                  ),
                )
              else
                ListenableBuilder(
                  listenable: gridConfig,
                  builder: (context, _) {
                    return SliverPadding(
                      padding: const EdgeInsets.all(4),
                      sliver: SliverMasonryGrid.count(
                        crossAxisCount: gridConfig.gridColumns,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                        itemBuilder: (context, index) {
                          final image = viewModel.images[index];
                          return ImageGridItem(
                            image: image,
                            heroTag: 'home-${image.index}',
                          );
                        },
                        childCount: viewModel.images.length,
                      ),
                    );
                  },
                ),
              if (viewModel.isLoading && viewModel.images.isNotEmpty)
                const SliverToBoxAdapter(child: LinearProgressIndicator()),
            ],
          );
        },
      ),
    );
  }
}
