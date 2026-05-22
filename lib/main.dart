import 'package:shared_preferences/shared_preferences.dart';
import 'package:tvplus/integrations/supabase_service.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/services.dart'; // Asegúrate de tener este import
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tvplus/globals/app_state.dart';
import 'package:tvplus/globals/router.dart';
import 'package:media_kit/media_kit.dart';

@NowaGenerated()
main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. FORZAR ORIENTACIÓN HORIZONTAL DE INMEDIATO
  // Esto anula cualquier configuración automática que Nowa intente inyectar después
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  // 2. INICIALIZACIÓN DE MOTOR DE VIDEO EN EL MAIN
  MediaKit.ensureInitialized();

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
    // Limpio: quitamos MediaKit de aquí para evitar el bug de escala
  }

  @override
  void dispose() {
    super.dispose();
    // Limpio: quitamos el SystemChrome.setEnabledSystemUIMode de aquí 
    // porque rompía la interfaz al renderizar la app raíz
  }
}
