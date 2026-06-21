import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'package:archive/archive.dart';
import 'package:xml/xml.dart' as xml;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:uuid/uuid.dart';
import '../models/post_model.dart';

/// FileParserService is responsible for turning raw uploaded files
/// (PDF, PPTX, TXT) into a list of [PostModel]s that the feed can render.
///
/// ───────────────────────────────────────────────────────────────────────
/// HOW TO CONNECT A REAL LLM API (replace mock logic):
/// ───────────────────────────────────────────────────────────────────────
/// 1. After raw text extraction (see `_extractRawSections`), instead of
///    using `_mockSummarize()`, send the raw section text to your LLM:
///
///      final response = await http.post(
///        Uri.parse('https://api.openai.com/v1/chat/completions'),
///        headers: {
///          'Authorization': 'Bearer YOUR_API_KEY',
///          'Content-Type': 'application/json',
///        },
///        body: jsonEncode({
///          'model': 'gpt-4o-mini',
///          'messages': [
///            {
///              'role': 'system',
///              'content': 'You convert lecture slide text into a short '
///                  'punchy tweet-style summary (mainContent) and a '
///                  'one-sentence elaboration (threadNote). Return JSON: '
///                  '{"title": "...", "mainContent": "...", "threadNote": "..."}'
///            },
///            {'role': 'user', 'content': rawSectionText},
///          ],
///        }),
///      );
///      final json = jsonDecode(response.body);
///      // parse json['choices'][0]['message']['content'] (which is itself JSON)
///
/// 2. Map the parsed {title, mainContent, threadNote} into a PostModel,
///    keeping the same image-extraction logic below untouched.
/// ───────────────────────────────────────────────────────────────────────
class FileParserService {
  final Uuid _uuid = const Uuid();
  final Random _rand = Random();

  /// Entry point: detects file type by extension and routes accordingly.
  Future<List<PostModel>> parseFile(File file) async {
    final lowerName = file.path.toLowerCase();
    if (lowerName.endsWith('.pdf')) {
      return _parsePdf(file);
    } else if (lowerName.endsWith('.pptx')) {
      return _parsePptx(file);
    } else if (lowerName.endsWith('.txt')) {
      return _parseTxt(file);
    } else {
      throw UnsupportedError('Unsupported file type: ${file.path}');
    }
  }

  // ──────────────────────────────────────────────────────────────────
  // PDF PARSING
  // ──────────────────────────────────────────────────────────────────
  Future<List<PostModel>> _parsePdf(File file) async {
    final bytes = await file.readAsBytes();
    final document = PdfDocument(inputBytes: bytes);
    final posts = <PostModel>[];

    final fileName = file.path.split(Platform.pathSeparator).last;

    for (int i = 0; i < document.pages.count; i++) {
      final extractor = PdfTextExtractor(document);
      final pageText = extractor
          .extractText(startPageIndex: i, endPageIndex: i)
          .trim();

      if (pageText.isEmpty) continue;

      // Extract embedded images on this page (if any)
      final List<Uint8List> images = [];
      try {
        final pageImages = PdfImageExtractor(document).extractImages(i);
        if (pageImages != null) {
          for (final img in pageImages) {
            images.add(Uint8List.fromList(img.imageData));
          }
        }
      } catch (_) {
        // Some pages may not have extractable images — safe to ignore.
      }

      final parsedSection = _mockSummarize(pageText, pageNumber: i + 1);

      posts.add(PostModel(
        id: _uuid.v4(),
        username: parsedSection.title,
        handle: _toHandle(parsedSection.title),
        mainContent: parsedSection.mainContent,
        threadNote: parsedSection.threadNote,
        images: images,
        sourceFileName: fileName,
        likeCount: _rand.nextInt(900) + 10,
        retweetCount: _rand.nextInt(300) + 2,
        commentCount: _rand.nextInt(120) + 1,
        timeAgo: _mockTimeAgo(i),
      ));
    }

    document.dispose();
    return posts;
  }

  // ──────────────────────────────────────────────────────────────────
  // PPTX PARSING
  // PPTX files are ZIP archives containing XML per slide
  // (ppt/slides/slideN.xml) plus embedded media (ppt/media/*).
  // ──────────────────────────────────────────────────────────────────
  Future<List<PostModel>> _parsePptx(File file) async {
    final bytes = await file.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);
    final fileName = file.path.split(Platform.pathSeparator).last;

    // Collect slide XML files in correct numeric order.
    final slideFiles = archive.files
        .where((f) =>
            f.isFile &&
            f.name.startsWith('ppt/slides/slide') &&
            f.name.endsWith('.xml'))
        .toList();

    slideFiles.sort((a, b) {
      final numA = _extractSlideNumber(a.name);
      final numB = _extractSlideNumber(b.name);
      return numA.compareTo(numB);
    });

    // Collect all media images once; we attach images per-slide using
    // the slide's relationship file (ppt/slides/_rels/slideN.xml.rels).
    final mediaFiles = {
      for (final f in archive.files.where((f) => f.name.startsWith('ppt/media/')))
        f.name: Uint8List.fromList(f.content as List<int>)
    };

    final posts = <PostModel>[];

    for (int i = 0; i < slideFiles.length; i++) {
      final slideFile = slideFiles[i];
      final xmlString = String.fromCharCodes(slideFile.content as List<int>);
      final document = xml.XmlDocument.parse(xmlString);

      // All visible text runs live inside <a:t> tags.
      final textNodes = document.findAllElements('a:t');
      final allText = textNodes.map((n) => n.innerText.trim()).where((t) => t.isNotEmpty).toList();

      if (allText.isEmpty) continue;

      // Heuristic: first text block = title/heading, rest = body/notes.
      final title = allText.first;
      final body = allText.skip(1).join(' ');

      // Try to find this slide's related images via its .rels file.
      final relsPath =
          'ppt/slides/_rels/${slideFile.name.split('/').last}.rels';
      final List<Uint8List> images = [];
      final relsFile = archive.files.firstWhere(
        (f) => f.name == relsPath,
        orElse: () => ArchiveFile('', 0, []),
      );
      if (relsFile.name.isNotEmpty) {
        final relsXml = xml.XmlDocument.parse(
            String.fromCharCodes(relsFile.content as List<int>));
        for (final rel in relsXml.findAllElements('Relationship')) {
          final target = rel.getAttribute('Target') ?? '';
          if (target.contains('media/')) {
            final mediaKey = 'ppt/${target.replaceFirst('../', '')}';
            if (mediaFiles.containsKey(mediaKey)) {
              images.add(mediaFiles[mediaKey]!);
            }
          }
        }
      }

      final parsedSection = _mockSummarize(body.isNotEmpty ? body : title, pageNumber: i + 1, fallbackTitle: title);

      posts.add(PostModel(
        id: _uuid.v4(),
        username: title,
        handle: _toHandle(title),
        mainContent: parsedSection.mainContent,
        threadNote: parsedSection.threadNote,
        images: images,
        sourceFileName: fileName,
        likeCount: _rand.nextInt(900) + 10,
        retweetCount: _rand.nextInt(300) + 2,
        commentCount: _rand.nextInt(120) + 1,
        timeAgo: _mockTimeAgo(i),
      ));
    }

    return posts;
  }

  int _extractSlideNumber(String path) {
    final match = RegExp(r'slide(\d+)\.xml').firstMatch(path);
    return match != null ? int.parse(match.group(1)!) : 0;
  }

  // ──────────────────────────────────────────────────────────────────
  // PLAIN TEXT PARSING
  // Splits on double newlines / headings to form separate "posts".
  // ──────────────────────────────────────────────────────────────────
  Future<List<PostModel>> _parseTxt(File file) async {
    final content = await file.readAsString();
    final fileName = file.path.split(Platform.pathSeparator).last;

    // Split into chunks by blank lines (paragraph-based sectioning).
    final rawSections = content
        .split(RegExp(r'\n\s*\n'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final posts = <PostModel>[];

    for (int i = 0; i < rawSections.length; i++) {
      final section = rawSections[i];
      final lines = section.split('\n');
      final title = lines.first.trim();
      final body = lines.skip(1).join(' ').trim();

      final parsedSection = _mockSummarize(
        body.isNotEmpty ? body : title,
        pageNumber: i + 1,
        fallbackTitle: title,
      );

      posts.add(PostModel(
        id: _uuid.v4(),
        username: title.length > 40 ? 'Section ${i + 1}' : title,
        handle: _toHandle(title),
        mainContent: parsedSection.mainContent,
        threadNote: parsedSection.threadNote,
        images: const [],
        sourceFileName: fileName,
        likeCount: _rand.nextInt(900) + 10,
        retweetCount: _rand.nextInt(300) + 2,
        commentCount: _rand.nextInt(120) + 1,
        timeAgo: _mockTimeAgo(i),
      ));
    }

    return posts;
  }

  // ──────────────────────────────────────────────────────────────────
  // MOCK "LLM" SUMMARIZER
  // Replace the body of this method with a real LLM API call (see
  // class-level doc comment above) to get genuinely intelligent
  // tweet-style summaries + thread notes.
  // ──────────────────────────────────────────────────────────────────
  _ParsedSection _mockSummarize(String rawText, {required int pageNumber, String? fallbackTitle}) {
    final cleaned = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Naive split: first sentence(s) -> main tweet, rest -> thread note.
    final sentences = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
    String main;
    String? thread;

    if (sentences.isEmpty) {
      main = cleaned;
      thread = null;
    } else if (sentences.length == 1) {
      main = sentences.first;
      thread = null;
    } else {
      // Take up to ~220 chars for the main tweet.
      final buffer = StringBuffer();
      int idx = 0;
      while (idx < sentences.length && buffer.length < 220) {
        buffer.write('${sentences[idx]} ');
        idx++;
      }
      main = buffer.toString().trim();
      if (idx < sentences.length) {
        thread = sentences.sublist(idx).join(' ').trim();
      }
    }

    if (main.isEmpty) main = fallbackTitle ?? 'Slide $pageNumber';

    return _ParsedSection(
      title: fallbackTitle ?? 'Slide $pageNumber',
      mainContent: main,
      threadNote: (thread != null && thread.isNotEmpty) ? thread : null,
    );
  }

  String _toHandle(String title) {
    final clean = title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
        .trim()
        .split(RegExp(r'\s+'))
        .take(3)
        .join('_');
    return '@${clean.isEmpty ? 'studyfeed' : clean}';
  }

  String _mockTimeAgo(int index) {
    final options = ['now', '1m', '5m', '12m', '1h', '2h', '3h'];
    return options[index % options.length];
  }
}

class _ParsedSection {
  final String title;
  final String mainContent;
  final String? threadNote;

  _ParsedSection({
    required this.title,
    required this.mainContent,
    this.threadNote,
  });
}
