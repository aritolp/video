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
  }

  @override
  void dispose() {
    //reestablece la visibilidad de la barra del sistema
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }
} //esta es la llave que cierra la clase_MyAppState
