import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/product.dart';
import 'database_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final DatabaseService _databaseService = DatabaseService();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
  }

  Future<bool> requestPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> checkLowStockProducts() async {
    try {
      final lowStockProducts = await _databaseService.getLowStockProducts();
      
      if (lowStockProducts.isNotEmpty) {
        for (final product in lowStockProducts) {
          await _showLowStockNotification(product);
        }
      }
    } catch (e) {
      print('Error checking low stock products: $e');
    }
  }

  Future<void> _showLowStockNotification(Product product) async {
    const androidDetails = AndroidNotificationDetails(
      'low_stock_channel',
      'Low Stock Alerts',
      channelDescription: 'Notifications for low stock products',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      product.id ?? 0,
      'Low Stock Alert',
      '${product.name} (${product.uniqueCode}) has only ${product.stockQuantity} items left!',
      details,
    );
  }

  Future<void> showSuccessNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'success_channel',
      'Success Notifications',
      channelDescription: 'Success operation notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  Future<void> showErrorNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'error_channel',
      'Error Notifications',
      channelDescription: 'Error operation notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
    );
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }
}
