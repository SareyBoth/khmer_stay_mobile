import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import 'app_state.dart';
import 'router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final khmer = state.locale.languageCode == 'km';
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'KhmerStay',
      locale: state.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(khmer: khmer),
      darkTheme: AppTheme.dark(khmer: khmer),
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: MediaQuery.textScalerOf(
            context,
          ).clamp(minScaleFactor: .8, maxScaleFactor: 2),
        ),
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}
