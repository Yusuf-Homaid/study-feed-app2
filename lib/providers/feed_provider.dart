import 'dart:io';
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/file_parser_service.dart';

enum UploadStatus { idle, processing, success, error }

/// Holds the global feed of posts generated from uploaded files,
/// plus the current processing status for the upload screen.
class FeedProvider extends ChangeNotifier {
  final FileParserService _parserService = FileParserService();

  final List<PostModel> _posts = [];
  UploadStatus _status = UploadStatus.idle;
  String? _errorMessage;
  final List<String> _processedFileNames = [];

  List<PostModel> get posts => List.unmodifiable(_posts);
  UploadStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<String> get processedFileNames => List.unmodifiable(_processedFileNames);
  bool get hasPosts => _posts.isNotEmpty;

  /// Processes a batch of picked files and appends generated posts to the feed.
  Future<void> processFiles(List<File> files) async {
    _status = UploadStatus.processing;
    _errorMessage = null;
    notifyListeners();

    try {
      for (final file in files) {
        final newPosts = await _parserService.parseFile(file);
        _posts.addAll(newPosts);
        _processedFileNames.add(file.path.split(Platform.pathSeparator).last);
      }
      _status = UploadStatus.success;
    } catch (e) {
      _status = UploadStatus.error;
      _errorMessage = 'Failed to process file(s): $e';
    }
    notifyListeners();
  }

  void clearFeed() {
    _posts.clear();
    _processedFileNames.clear();
    _status = UploadStatus.idle;
    notifyListeners();
  }

  void resetStatus() {
    _status = UploadStatus.idle;
    notifyListeners();
  }
}
