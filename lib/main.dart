import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/feed_provider.dart';
import 'providers/settings_provider.dart';
import 'screens/upload_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const StudyFeedApp());
}

class StudyFeedApp extends StatelessWidget {
  const StudyFeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FeedProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
      ],
      child: MaterialApp(
        title: 'StudyFeed',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkPure(),
        darkTheme: AppTheme.darkPure(),
        themeMode: ThemeMode.dark,
        home: const UploadScreen(),
      ),
    );
  }
}
