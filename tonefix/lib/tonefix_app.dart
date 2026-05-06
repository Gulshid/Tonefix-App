import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tonefix/core/di/injection_container.dart';
import 'package:tonefix/core/theme/app_theme.dart';
import 'package:tonefix/core/theme/theme_cubit.dart';
import 'package:tonefix/features/home/bloc/home_bloc.dart';
import 'package:tonefix/features/home/bloc/home_event.dart';
import 'package:tonefix/features/history/bloc/history_bloc.dart';
import 'package:tonefix/features/history/bloc/history_event.dart';
import 'package:tonefix/features/tone_rewrite/bloc/tone_rewrite_bloc.dart';
import 'package:tonefix/routes/app_router.dart';

class ToneFixApp extends StatefulWidget {
  const ToneFixApp({super.key});

  @override
  State<ToneFixApp> createState() => _ToneFixAppState();
}

class _ToneFixAppState extends State<ToneFixApp> {
  late final _router = AppRouter.create();

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => sl<ThemeCubit>()),
        BlocProvider(
          create: (_) => sl<HomeBloc>()..add(const HomeInitEvent()),
        ),
        BlocProvider(
          create: (_) => sl<HistoryBloc>()..add(const HistoryLoadEvent()),
        ),
        BlocProvider(create: (_) => sl<ToneRewriteBloc>()),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ScreenUtilInit(
            designSize: _designSize(constraints.maxWidth),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, __) => _AppEntry(router: _router),
          );
        },
      ),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry({required this.router});
  final RouterConfig<Object> router;

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<ThemeCubit>().state;

    return MaterialApp.router(
      title: 'ToneFix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (ctx, child) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
        );
        return child!;
      },
    );
  }
}

/// Responsive design size — mirrors your demo app pattern
Size _designSize(double width) {
  if (width < 600) return const Size(360, 800);   // phone
  if (width < 1200) return const Size(834, 1194); // tablet
  return const Size(1440, 1024);                   // desktop
}
