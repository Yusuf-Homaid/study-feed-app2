import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../models/post_model.dart';
import '../providers/settings_provider.dart';
import '../screens/lightbox_screen.dart';
import '../theme/app_theme.dart';

/// Renders a single educational "post" in the X-style feed:
/// avatar + username/handle, main tweet content, optional image grid,
/// optional connected thread note, and a static action bar
/// (like / comment / retweet / share).
class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _liked = false;
  bool _retweeted = false;

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final post = widget.post;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureBlack,
        border: Border(
          bottom: BorderSide(color: AppColors.borderGrey, width: 0.6),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(seed: post.username),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(post: post, settings: settings),
                const SizedBox(height: 2),
                // Main tweet content, inside a subtle dark-grey card
                _ContentCard(
                  child: Text(
                    post.mainContent,
                    style: settings.scaledStyle(baseSize: 15, color: AppColors.white),
                  ),
                ),
                if (post.images.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _ImageGrid(images: post.images),
                ],
                if (post.threadNote != null) ...[
                  const SizedBox(height: 10),
                  _ThreadNote(post: post, settings: settings),
                ],
                const SizedBox(height: 8),
                _ActionBar(
                  post: post,
                  liked: _liked,
                  retweeted: _retweeted,
                  onLike: () => setState(() => _liked = !_liked),
                  onRetweet: () => setState(() => _retweeted = !_retweeted),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final PostModel post;
  final SettingsProvider settings;
  const _Header({required this.post, required this.settings});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            post.username,
            overflow: TextOverflow.ellipsis,
            style: settings.scaledStyle(
              baseSize: 15,
              weight: FontWeight.w800,
              color: AppColors.white,
            ),
          ),
        ),
        if (post.verified) const Padding(
          padding: EdgeInsets.only(left: 3),
          child: Icon(Icons.verified, size: 16, color: AppColors.blue),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            '${post.handle} · ${post.timeAgo}',
            overflow: TextOverflow.ellipsis,
            style: settings.scaledStyle(baseSize: 14, color: AppColors.secondaryText),
          ),
        ),
        const Spacer(),
        const Icon(Icons.more_horiz, size: 18, color: AppColors.secondaryText),
      ],
    );
  }
}

/// Subtle dark-grey card overlaying the pure-black background,
/// as required: "Post Card" with dark grey on top of #000000.
class _ContentCard extends StatelessWidget {
  final Widget child;
  const _ContentCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardGrey,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGrey, width: 0.6),
      ),
      child: child,
    );
  }
}

class _ThreadNote extends StatelessWidget {
  final PostModel post;
  final SettingsProvider settings;
  const _ThreadNote({required this.post, required this.settings});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thread connector line + small avatar to mimic X's reply thread look
          Column(
            children: [
              const SizedBox(height: 4),
              _Avatar(seed: '${post.username}_note', size: 28),
              Expanded(
                child: Container(
                  width: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: AppColors.borderGrey,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.cardGrey.withOpacity(0.6),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderGrey, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Professor\'s Note',
                        style: settings.scaledStyle(
                          baseSize: 13,
                          weight: FontWeight.w700,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(FontAwesomeIcons.chalkboardUser, size: 12, color: AppColors.secondaryText),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    post.threadNote!,
                    style: settings.scaledStyle(baseSize: 14.5, color: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List images; // List<Uint8List>
  const _ImageGrid({required this.images});

  @override
  Widget build(BuildContext context) {
    final displayImages = images.take(4).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: displayImages.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: displayImages.length == 1 ? 1 : 2,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
          childAspectRatio: displayImages.length == 1 ? 16 / 10 : 1,
        ),
        itemBuilder: (context, index) {
          final bytes = displayImages[index];
          return GestureDetector(
            onTap: () => Navigator.of(context).push(LightboxScreen.route(bytes)),
            child: Hero(
              tag: 'lightbox-image-$index-${bytes.hashCode}',
              child: Image.memory(
                bytes,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.cardGrey,
                  child: const Icon(Icons.broken_image, color: AppColors.secondaryText),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String seed;
  final double size;
  const _Avatar({required this.seed, this.size = 42});

  @override
  Widget build(BuildContext context) {
    final colors = [
      const Color(0xFF1D9BF0),
      const Color(0xFF00BA7C),
      const Color(0xFFF91880),
      const Color(0xFFFFAD1F),
      const Color(0xFF7856FF),
    ];
    final color = colors[seed.hashCode.abs() % colors.length];
    final initial = seed.trim().isNotEmpty ? seed.trim()[0].toUpperCase() : 'S';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.42,
        ),
      ),
    );
  }
}

/// Static (cosmetically interactive) action row: comment, retweet, like, share.
class _ActionBar extends StatelessWidget {
  final PostModel post;
  final bool liked;
  final bool retweeted;
  final VoidCallback onLike;
  final VoidCallback onRetweet;

  const _ActionBar({
    required this.post,
    required this.liked,
    required this.retweeted,
    required this.onLike,
    required this.onRetweet,
  });

  @override
  Widget build(BuildContext context) {
    final likeCount = post.likeCount + (liked ? 1 : 0);
    final retweetCount = post.retweetCount + (retweeted ? 1 : 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _ActionItem(
          icon: FontAwesomeIcons.comment,
          count: post.commentCount,
          color: AppColors.secondaryText,
          onTap: () {},
        ),
        _ActionItem(
          icon: FontAwesomeIcons.retweet,
          count: retweetCount,
          color: retweeted ? AppColors.retweetGreen : AppColors.secondaryText,
          activeColor: AppColors.retweetGreen,
          isActive: retweeted,
          onTap: onRetweet,
        ),
        _ActionItem(
          icon: liked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
          count: likeCount,
          color: liked ? AppColors.likePink : AppColors.secondaryText,
          activeColor: AppColors.likePink,
          isActive: liked,
          onTap: onLike,
        ),
        _ActionItem(
          icon: FontAwesomeIcons.arrowUpFromBracket,
          count: null,
          color: AppColors.secondaryText,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final int? count;
  final Color color;
  final Color? activeColor;
  final bool isActive;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.count,
    required this.color,
    required this.onTap,
    this.activeColor,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            if (count != null) ...[
              const SizedBox(width: 6),
              Text(
                _formatCount(count!),
                style: TextStyle(fontSize: 12.5, color: color),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
