import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

@NowaGenerated()
class ForegroundTaskHelper {
  static void init() {}

  static Future<void> start(String title) async {
    await WakelockPlus.enable();
  }

  static void stop() {
    WakelockPlus.disable();
  }
}
