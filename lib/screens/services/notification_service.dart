import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────
// 🔔 NotificationService
// ─────────────────────────────────────────────
class NotificationService {
  // Singleton — instance واحد في كل التطبيق
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // ─── Initialize ──────────────────────────────
  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // طلب صلاحية Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  // ─── Show ─────────────────────────────────────
  Future<void> show({
    required int id,
    required String title,
    required String body,
    _Channel channel = _Channel.general,
  }) async {
    await init();

    final AndroidNotificationDetails android = AndroidNotificationDetails(
      channel.id,
      channel.name,
      channelDescription: channel.desc,
      importance: Importance.high,
      priority: Priority.high,
      color: const Color(0xFF1E6FFF),
      playSound: true,
      enableVibration: true,
      styleInformation: BigTextStyleInformation(body),
    );

    const DarwinNotificationDetails ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
    );
  }

  // ─────────────────────────────────────────────
  // ✅ للمواطن — لما يتغير status بلاغه
  // ─────────────────────────────────────────────
  Future<void> notifyCitizen({
    required String status,
    required String description,
  }) async {
    String title;
    String body;

    switch (status) {
      case 'assigned':
        title = '👷 تم إسناد بلاغك';
        body = 'بلاغك "$description" تم إسناده لعامل وسيتم معالجته قريباً';
        break;
      case 'in_progress':
        title = '🔄 بلاغك قيد المعالجة';
        body = 'يعمل الفريق الآن على معالجة بلاغك "$description"';
        break;
      case 'completed':
        title = '✅ تم حل بلاغك!';
        body = 'تم حل بلاغك "$description" بنجاح. شكراً لمساهمتك!';
        break;
      default:
        return;
    }

    await show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      channel: _Channel.citizen,
    );
  }

  // ─────────────────────────────────────────────
  // 👷 للعامل — لما يُسند له بلاغ جديد
  // ─────────────────────────────────────────────
  Future<void> notifyWorker({
    required String description,
    required String category,
  }) async {
    await show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '📋 مهمة جديدة مُسندة إليك',
      body: 'لديك مهمة جديدة: "$description" — الفئة: $category',
      channel: _Channel.worker,
    );
  }

  // ─────────────────────────────────────────────
  // 🚨 للأدمين والإدارة — لما يأتي بلاغ جديد
  // ─────────────────────────────────────────────
  Future<void> notifyAdmin({
    required String description,
    required String category,
  }) async {
    await show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: '🚨 بلاغ جديد وارد',
      body: 'بلاغ جديد: "$description" — الفئة: $category',
      channel: _Channel.admin,
    );
  }
}

// ─────────────────────────────────────────────
// 📢 Channels
// ─────────────────────────────────────────────
enum _Channel {
  general('general', 'عام', 'إشعارات عامة'),
  citizen('citizen', 'بلاغات المواطن', 'تحديثات حالة البلاغات'),
  worker('worker', 'مهام العامل', 'مهام جديدة مسندة'),
  admin('admin', 'الإدارة', 'بلاغات جديدة وتحديثات');

  final String id;
  final String name;
  final String desc;
  const _Channel(this.id, this.name, this.desc);
}
