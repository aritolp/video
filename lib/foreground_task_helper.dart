import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
class ForegroundTaskHelper {
  static void init() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'tvplus_playback',
        channelName: 'TV Plus Reproducción',
        channelDescription: 'Mantiene la reproducción activa en segundo plano',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> start(String title) async {
    if (await FlutterForegroundTask.isRunningService) {
      FlutterForegroundTask.updateService(
        notificationTitle: 'TV Plus: ${title}',
      );
    } else {
      FlutterForegroundTask.startService(
        notificationTitle: 'TV Plus: ${title}',
        notificationText: 'Reproduciendo en segundo plano',
      );
    }
  }

  static void stop() {
    FlutterForegroundTask.stopService();
  }
}
