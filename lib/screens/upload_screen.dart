import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/feed_provider.dart';
import '../theme/app_theme.dart';
import 'feed_screen.dart';

/// Dedicated screen for uploading source educational files
/// (PDF, PPTX, TXT) before they're converted into the study feed.
class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final List<File> _selectedFiles = [];

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'pptx', 'txt'],
    );

    if (result != null) {
      setState(() {
        _selectedFiles.addAll(
          result.paths.whereType<String>().map((p) => File(p)),
        );
      });
    }
  }

  void _removeFile(File file) {
    setState(() => _selectedFiles.remove(file));
  }

  Future<void> _processAndGoToFeed() async {
    if (_selectedFiles.isEmpty) return;
    final feedProvider = context.read<FeedProvider>();
    await feedProvider.processFiles(_selectedFiles);

    if (!mounted) return;

    if (feedProvider.status == UploadStatus.success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const FeedScreen()),
      );
    } else if (feedProvider.status == UploadStatus.error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(feedProvider.errorMessage ?? 'Something went wrong')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedProvider = context.watch<FeedProvider>();
    final isProcessing = feedProvider.status == UploadStatus.processing;

    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      appBar: AppBar(
        title: const Text(
          'StudyFeed',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.white),
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Turn your notes into a feed',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Upload PDFs, PowerPoint slides, or plain text — '
                'we\'ll turn each heading into a post and your notes '
                'into a connected thread.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: isProcessing ? null : _pickFiles,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: AppColors.cardGrey,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.borderGrey,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    children: const [
                      Icon(FontAwesomeIcons.cloudArrowUp, size: 36, color: AppColors.blue),
                      SizedBox(height: 12),
                      Text(
                        'Tap to choose files',
                        style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PDF · PPTX · TXT  (multiple allowed)',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_selectedFiles.isNotEmpty) ...[
                const Text(
                  'Selected files',
                  style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    itemCount: _selectedFiles.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final file = _selectedFiles[index];
                      final name = file.path.split(Platform.pathSeparator).last;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(_iconForFile(name), color: AppColors.blue, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.white, fontSize: 13),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18, color: AppColors.secondaryText),
                              onPressed: isProcessing ? null : () => _removeFile(file),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ] else
                const Spacer(),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: (_selectedFiles.isEmpty || isProcessing) ? null : _processAndGoToFeed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.cardGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.pureBlack),
                        )
                      : Text(
                          'Generate Study Feed',
                          style: TextStyle(
                            color: _selectedFiles.isEmpty ? AppColors.secondaryText : AppColors.pureBlack,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForFile(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return FontAwesomeIcons.filePdf;
    if (lower.endsWith('.pptx')) return FontAwesomeIcons.filePowerpoint;
    return FontAwesomeIcons.fileLines;
  }
}
