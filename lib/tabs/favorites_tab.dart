import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '../logic/viewmodels/home_view_model.dart';
import '../main.dart';
import '../services/favorite_service.dart';
import '../widgets/image_grid_item.dart';

class FavoritesTab extends StatefulWidget {
  final HomeViewModel viewModel;

  const FavoritesTab({super.key, required this.viewModel});

  @override
  State<FavoritesTab> createState() => FavoritesTabState();
}

class FavoritesTabState extends State<FavoritesTab>
    with AutomaticKeepAliveClientMixin {
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
    final config = AppDependencies.instance.configViewModel;

    return Builder(
      builder: (context) => ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return CustomScrollView(
            primary: true,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverOverlapInjector(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
              ),
              ValueListenableBuilder<Set<String>>(
                valueListenable: FavoriteService.favoritesNotifier,
                builder: (context, favoriteShas, _) {
                  final favoriteImages = widget.viewModel.images
                      .where((img) => favoriteShas.contains(img.sha))
                      .toList();

                  if (favoriteImages.isEmpty && !widget.viewModel.isLoading) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border_rounded,
                              size: 42,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có ảnh yêu thích nào',
                              style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.75),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListenableBuilder(
                    listenable: config,
                    builder: (context, _) {
                      return SliverPadding(
                        padding: const EdgeInsets.all(4),
                        sliver: SliverMasonryGrid.count(
                          crossAxisCount: config.gridColumns,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 4,
                          itemBuilder: (context, index) {
                            final image = favoriteImages[index];
                            return ImageGridItem(
                              image: image,
                              heroTag: 'fav-${image.index}',
                            );
                          },
                          childCount: favoriteImages.length,
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
