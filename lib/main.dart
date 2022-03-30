import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lazy1922/models/code.dart';
import 'package:lazy1922/models/place.dart';
import 'package:lazy1922/models/record.dart';
import 'package:lazy1922/models/user.dart';
import 'package:lazy1922/providers/inactive_start_time_provider.dart';
import 'package:lazy1922/providers/selected_page_provider.dart';
import 'package:lazy1922/providers/user_provider.dart';
import 'package:lazy1922/screens/home_screen.dart';
import 'package:lazy1922/screens/premium_screen.dart';
import 'package:lazy1922/theme.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:vrouter/vrouter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive
    ..registerAdapter<Code>(CodeAdapter())
    ..registerAdapter<Record>(RecordAdapter())
    ..registerAdapter<Place>(PlaceAdapter())
    ..registerAdapter<User>(UserAdapter());
  await Future.wait([
    Hive.openBox<List>("records"),
    Hive.openBox<List>("places"),
    Hive.openBox<User>("users"),
    dotenv.load(fileName: ".env"),
    EasyLocalization.ensureInitialized(),
  ]);

  Purchases.setDebugLogsEnabled(true);

  if (Platform.isAndroid) {
    Purchases.setup(dotenv.env['PUBLIC_GOOGLE_SDK_KEY']!);
  } else if (Platform.isIOS) {
    Purchases.setup(dotenv.env['PUBLIC_IOS_SDK_KEY']!);
  }

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('zh', 'TW'),
        // Locale('ja', 'JP'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('zh', 'TW'),
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance!.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance!.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final user = ref.read(userProvider);
      final inactiveStartTime = ref.read(inactiveStartTimeProvider);
      if (DateTime.now().difference(inactiveStartTime).inMinutes >= user.autoReturn) {
        ref.refresh(selectedPageProvider);
      }
    } else if (state == AppLifecycleState.paused) {
      final inactiveStartTimeNotifier = ref.read(inactiveStartTimeProvider.notifier);
      inactiveStartTimeNotifier.state = DateTime.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    return VRouter(
      title: 'Lazy1922',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.teal,
        appBarTheme: appBarTheme(context, Brightness.light),
        cardTheme: cardTheme,
        dialogTheme: dialogTheme,
        floatingActionButtonTheme: floatingActionButtonTheme,
        inputDecorationTheme: inputDecorationTheme,
        textButtonTheme: textButtonTheme,
        elevatedButtonTheme: elevatedButtonTheme,
        outlinedButtonTheme: outlinedButtonTheme,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        appBarTheme: appBarTheme(context, Brightness.dark),
        cardTheme: cardTheme,
        dialogTheme: dialogTheme,
        floatingActionButtonTheme: floatingActionButtonTheme,
        inputDecorationTheme: inputDecorationTheme,
        textButtonTheme: textButtonTheme,
        elevatedButtonTheme: elevatedButtonTheme,
        outlinedButtonTheme: outlinedButtonTheme,
      ),
      themeMode: ThemeMode.system,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      initialUrl: '/',
      routes: [
        VWidget(
          name: 'home',
          path: '/',
          widget: const HomeScreen(),
          stackedRoutes: [
            VWidget(
              name: 'premium',
              path: '/premium',
              widget: const PremiumScreen(),
            ),
          ],
        ),
      ],
    );
  }
}
