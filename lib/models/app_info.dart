import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
class AppInfo {
  AppInfo({
    required this.nombreApp,
    required this.version,
    required this.correo,
    required this.sitioWeb,
  });

  factory AppInfo.fromJson(Map<String, dynamic> json) {
    return AppInfo(
      nombreApp: json['nombre_app'] ?? 'TV Plus',
      version: json['version'] ?? '1.0.0',
      correo: json['correo'] ?? '',
      sitioWeb: json['sitio_web'] ?? '',
    );
  }

  final String nombreApp;

  final String version;

  final String correo;

  final String sitioWeb;
}
