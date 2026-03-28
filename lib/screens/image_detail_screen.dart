import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ImageDetailScreen extends StatelessWidget {
  final String imageUrl;
  final Map<String, dynamic>? imageMap;

  const ImageDetailScreen({
    super.key,
    required this.imageUrl,
    this.imageMap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Giữ nền đen để Predictive Back nổi bật
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: CachedNetworkImage(
            imageUrl: imageMap != null && imageMap!['sha'] != null
                ? '$imageUrl?v=${imageMap!['sha']}'
                : imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
