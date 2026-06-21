import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/font_settings_bar.dart';
import '../widgets/post_card.dart';
import 'upload_screen.dart';

/// The main X-style scrollable timeline showing all generated posts.
class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final posts = feedProvider.posts;

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.white),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const UploadScreen()),
          ),
        ),
        title: const Text(
          'Study Feed',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppColors.white),
            tooltip: 'Upload more files',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const UploadScreen()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const FontSettingsBar(),
          Expanded(
            child: posts.isEmpty
                ? const _EmptyFeedState()
                : RefreshIndicator(
                    color: AppColors.blue,
                    backgroundColor: AppColors.cardGrey,
                    onRefresh: () async {
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) => PostCard(post: posts[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.feed_outlined, color: AppColors.secondaryText, size: 48),
          const SizedBox(height: 12),
          const Text(
            'No posts yet',
            style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 6),
          const Text(
            'Upload a file to generate your study feed',
            style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
