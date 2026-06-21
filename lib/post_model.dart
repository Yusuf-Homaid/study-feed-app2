import 'dart:typed_data';

/// Represents a single "tweet" derived from a slide/page/section
/// of an uploaded educational file.
class PostModel {
  final String id;

  /// Derived from slide title / heading -> shown as "Username" + "@handle"
  final String username;
  final String handle;

  /// Core slide content -> shown as the main tweet body
  final String mainContent;

  /// Teacher/professor notes -> shown as a threaded reply beneath the main tweet
  final String? threadNote;

  /// Extracted images (raw bytes) tied to this slide/section
  final List<Uint8List> images;

  /// Source file this post was generated from
  final String sourceFileName;

  /// Mock/randomized engagement stats to feel authentic
  final int likeCount;
  final int retweetCount;
  final int commentCount;

  /// Relative "time ago" string, purely cosmetic
  final String timeAgo;

  /// Whether the avatar should show a verified-style badge
  final bool verified;

  PostModel({
    required this.id,
    required this.username,
    required this.handle,
    required this.mainContent,
    this.threadNote,
    this.images = const [],
    required this.sourceFileName,
    this.likeCount = 0,
    this.retweetCount = 0,
    this.commentCount = 0,
    this.timeAgo = 'now',
    this.verified = true,
  });
}
