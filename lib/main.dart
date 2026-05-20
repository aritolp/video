import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvplus/integrations/supabase_service.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvplus/globals/app_state.dart';
import 'package:tvplus/globals/router.dart';
import 'package:media_kit/media_kit.dart';

@NowaGenerated()
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPrefs = await SharedPreferences.getInstance();
  await SupabaseService().initialize();
  runApp(const MyApp());
}

@NowaGenerated()
late final SharedPreferences sharedPrefs;

@NowaGenerated({'visibleInNowa': false})
class MyApp extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const MyApp({super.key});

  @override
  State<MyApp> createState() {
    return _MyAppState();
  }
}

@NowaGenerated()
class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (context) => AppState()),
      ],
      builder: (context, child) => MaterialApp.router(
        theme: AppState.of(context).theme,
        routerConfig: appRouter,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    MediaKit.ensureInitialized();

    // 1. Fuerza la visibilidad de la barra de notificaciones y navegación desde el inicio
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, 
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom]
    );

    // 2. Desbloquea todas las orientaciones para activar el sensor de giro
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    super.dispose();
  }
}
