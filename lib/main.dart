import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/tokens.dart';
import 'core/theme/typography.dart';
import 'gallery/gallery_page.dart';
export 'gallery/gallery_page.dart' show ScreenPage;

void main() => runApp(const PoPoApp());

class PoPoApp extends StatelessWidget {
  const PoPoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PoPo',
      debugShowCheckedModeBanner: false,

      // The whole UI is Persian and right-to-left. Technical values opt back out
      // individually through MonoText rather than the layout opting in.
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: TextDirection.rtl,
        child: child!,
      ),

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: C.page,
        fontFamily: kSans,
        colorScheme: const ColorScheme.dark(
          primary: C.primary,
          secondary: C.primaryMuted,
          surface: C.surface,
          error: C.danger,
          onPrimary: C.onPrimary,
          onSurface: C.heading,
        ),
      ),
      home: const GalleryPage(),
    );
  }
}
