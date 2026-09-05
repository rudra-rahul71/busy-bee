import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

/// A no-op implementation of [NotificationService] used for testing or headless
/// environments where native notification prompts should be suppressed.
class NoOpNotificationService implements NotificationService {
  @override
  Future<void> initialize({
    String defaultChannelId = 'default_channel',
    String defaultChannelName = 'Default Notifications',
    String defaultChannelDescription = 'Default app notifications',
    String defaultAndroidIcon = 'app_icon',
  }) async {}

  @override
  Future<bool> requestPermissions() async => true;

  @override
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required Duration duration,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) async {}

  @override
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? channelId,
    String? channelName,
    String? channelDescription,
  }) async {}

  @override
  Future<void> cancelNotification(int id) async {}

  @override
  Future<void> cancelAllNotifications() async {}
}
