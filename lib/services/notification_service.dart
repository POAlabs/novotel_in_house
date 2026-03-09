/// Push Notification Service
/// Handles Firebase Cloud Messaging (FCM) for push notifications
/// 
/// Features:
/// - FCM token management
/// - Permission requests (iOS/Android)
/// - Foreground/background notification handling
/// - Navigation on notification tap

import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'debug_log_service.dart';

/// Background message handler - must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('🔔 [NOTIFICATION] Background message received: ${message.messageId}');
  // Background messages are handled automatically by FCM
  // No need to show notification - FCM does it for us
}

class NotificationService {
  // Firebase Messaging instance
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  
  // Local notifications plugin for foreground display
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Firestore for storing tokens
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Debug logging
  final DebugLogService _debugLog = DebugLogService();
  
  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();
  
  // Current FCM token
  String? _fcmToken;
  String? get fcmToken => _fcmToken;
  
  // Callback for when a notification is tapped
  void Function(Map<String, dynamic> data)? onNotificationTap;

  /// Initialize the notification service
  /// Call this after Firebase.initializeApp()
  Future<void> initialize() async {
    debugPrint('🔔 [NOTIFICATION] Initializing notification service...');
    _debugLog.addLog('NOTIFICATION_SERVICE', 'Initializing');
    
    try {
      // Set up background message handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      
      // Initialize local notifications for foreground display
      await _initializeLocalNotifications();
      
      // Request permissions
      await _requestPermissions();
      
      // Get FCM token
      await _getFcmToken();
      
      // Listen for token refresh
      _messaging.onTokenRefresh.listen(
        _onTokenRefresh,
        onError: (error) {
          debugPrint('❌ [NOTIFICATION] Token refresh stream error: $error');
          _debugLog.addLog(
            'NOTIFICATION_SERVICE',
            'Token refresh stream error',
            data: {'error': error.toString()},
            isError: true,
          );
        },
      );
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen(
        _handleForegroundMessage,
        onError: (error) {
          debugPrint('❌ [NOTIFICATION] Foreground message stream error: $error');
          _debugLog.addLog(
            'NOTIFICATION_SERVICE',
            'Foreground message stream error',
            data: {'error': error.toString()},
            isError: true,
          );
        },
      );
      
      // Handle notification tap when app is in background/terminated
      FirebaseMessaging.onMessageOpenedApp.listen(
        _handleNotificationTap,
        onError: (error) {
          debugPrint('❌ [NOTIFICATION] Message opened stream error: $error');
          _debugLog.addLog(
            'NOTIFICATION_SERVICE',
            'Message opened stream error',
            data: {'error': error.toString()},
            isError: true,
          );
        },
      );
      
      // Check if app was opened from a notification
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('🔔 [NOTIFICATION] App opened from notification');
        _debugLog.addLog(
          'NOTIFICATION_SERVICE',
          'App opened from notification',
          data: {'messageId': initialMessage.messageId, 'data': initialMessage.data},
        );
        _handleNotificationTap(initialMessage);
      }
      
      debugPrint('✅ [NOTIFICATION] Service initialized successfully');
      _debugLog.addLog('NOTIFICATION_SERVICE', 'Initialized successfully', 
        data: {'token': _fcmToken?.substring(0, 20) ?? 'null'});
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Initialization failed: $e');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Initialization failed',
        data: {
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    try {
      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false, // We request separately
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      final initialized = await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onLocalNotificationTap,
      );
      
      if (initialized != true) {
        _debugLog.addLog(
          'NOTIFICATION_SERVICE',
          'Local notifications init returned false/null',
          data: {'result': initialized.toString()},
          isError: true,
        );
      }
      
      // Create notification channel for Android
      if (Platform.isAndroid) {
        const channel = AndroidNotificationChannel(
          'novotel_issues', // Channel ID
          'Issue Notifications', // Channel name
          description: 'Notifications for hotel issue updates',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        
        await _localNotifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
        
        _debugLog.addLog(
          'NOTIFICATION_SERVICE',
          'Android notification channel created',
          data: {'channelId': 'novotel_issues'},
        );
      }
      
      debugPrint('✅ [NOTIFICATION] Local notifications initialized');
      _debugLog.addLog('NOTIFICATION_SERVICE', 'Local notifications initialized');
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Local notifications init failed: $e');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Local notifications initialization failed',
        data: {
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    debugPrint('🔔 [NOTIFICATION] Requesting permissions...');
    
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      debugPrint('🔔 [NOTIFICATION] Permission status: ${settings.authorizationStatus}');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Permission requested',
        data: {
          'status': settings.authorizationStatus.toString(),
          'alert': settings.alert.toString(),
          'badge': settings.badge.toString(),
          'sound': settings.sound.toString(),
        },
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('⚠️ [NOTIFICATION] Notifications denied by user');
        _debugLog.addLog(
          'NOTIFICATION_SERVICE',
          'Notifications denied by user',
          data: {'status': 'denied'},
          isError: true,
        );
      } else if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        _debugLog.addLog(
          'NOTIFICATION_SERVICE',
          'Notification permission not determined',
          data: {'status': 'notDetermined'},
          isError: true,
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Permission request failed: $e');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Permission request failed',
        data: {
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
      rethrow;
    }
  }

  /// Get FCM token
  Future<String?> _getFcmToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      
      if (_fcmToken == null) {
        debugPrint('⚠️ [NOTIFICATION] FCM Token is null');
        _debugLog.addLog(
          'NOTIFICATION_SERVICE',
          'FCM token is null - push notifications will not work',
          data: {'platform': Platform.operatingSystem},
          isError: true,
        );
        return null;
      }
      
      debugPrint('🔔 [NOTIFICATION] FCM Token: ${_fcmToken!.substring(0, 30)}...');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'FCM token obtained',
        data: {
          'tokenPrefix': _fcmToken!.substring(0, 20),
          'tokenLength': _fcmToken!.length,
        },
      );
      return _fcmToken;
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Failed to get FCM token: $e');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Failed to get FCM token',
        data: {
          'error': e.toString(),
          'errorType': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
          'platform': Platform.operatingSystem,
        },
        isError: true,
      );
      return null;
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String newToken) {
    debugPrint('🔔 [NOTIFICATION] Token refreshed');
    final oldTokenPrefix = _fcmToken?.substring(0, 20) ?? 'null';
    _fcmToken = newToken;
    _debugLog.addLog(
      'NOTIFICATION_SERVICE',
      'Token refreshed',
      data: {
        'oldTokenPrefix': oldTokenPrefix,
        'newTokenPrefix': newToken.substring(0, 20),
        'newTokenLength': newToken.length,
      },
    );
    // Token will be updated in Firestore on next login or can be updated immediately
    // if we have the current user ID stored
  }

  /// Handle foreground messages - show local notification
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [NOTIFICATION] Foreground message: ${message.notification?.title}');
    _debugLog.addLog('NOTIFICATION_SERVICE', 'Foreground message received',
      data: {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });
    
    final notification = message.notification;
    if (notification != null) {
      _showLocalNotification(
        title: notification.title ?? 'Novotel Update',
        body: notification.body ?? '',
        payload: message.data,
      );
    }
  }

  /// Show a local notification (for foreground messages)
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      const androidDetails = AndroidNotificationDetails(
        'novotel_issues',
        'Issue Notifications',
        channelDescription: 'Notifications for hotel issue updates',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        icon: '@mipmap/ic_launcher',
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
      
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      await _localNotifications.show(
        notificationId,
        title,
        body,
        details,
        payload: payload?.toString(),
      );
      
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Local notification shown',
        data: {
          'notificationId': notificationId,
          'title': title,
          'bodyLength': body.length,
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Failed to show local notification: $e');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Failed to show local notification',
        data: {
          'error': e.toString(),
          'title': title,
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
    }
  }

  /// Handle notification tap (from background/terminated)
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🔔 [NOTIFICATION] Notification tapped: ${message.data}');
    _debugLog.addLog('NOTIFICATION_SERVICE', 'Notification tapped',
      data: message.data);
    
    if (onNotificationTap != null) {
      onNotificationTap!(message.data);
    }
  }

  /// Handle local notification tap
  void _onLocalNotificationTap(NotificationResponse response) {
    debugPrint('🔔 [NOTIFICATION] Local notification tapped: ${response.payload}');
    _debugLog.addLog('NOTIFICATION_SERVICE', 'Local notification tapped',
      data: {'payload': response.payload});
    
    // Parse payload and trigger callback if set
    if (onNotificationTap != null && response.payload != null) {
      // Note: payload is stored as string, would need parsing for actual data
      onNotificationTap!({'payload': response.payload});
    }
  }

  /// Store FCM token in Firestore for a user
  /// Call this after successful login
  Future<void> storeFcmToken(String userId) async {
    if (_fcmToken == null) {
      debugPrint('⚠️ [NOTIFICATION] No FCM token to store');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Cannot store FCM token - token is null',
        data: {'userId': userId},
        isError: true,
      );
      return;
    }
    
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': _fcmToken,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ [NOTIFICATION] FCM token stored for user: $userId');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Token stored in Firestore',
        data: {
          'userId': userId,
          'tokenPrefix': _fcmToken!.substring(0, 20),
        },
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Failed to store FCM token: $e');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Failed to store FCM token in Firestore',
        data: {
          'userId': userId,
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
    }
  }

  /// Clear FCM token from Firestore (on logout)
  Future<void> clearFcmToken(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'fcmToken': FieldValue.delete(),
        'fcmTokenUpdatedAt': FieldValue.delete(),
      });
      
      debugPrint('✅ [NOTIFICATION] FCM token cleared for user: $userId');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Token cleared from Firestore',
        data: {'userId': userId},
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Failed to clear FCM token: $e');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Failed to clear FCM token from Firestore',
        data: {
          'userId': userId,
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
    }
  }

  /// Subscribe to a topic (e.g., department or role-based notifications)
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ [NOTIFICATION] Subscribed to topic: $topic');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Subscribed to topic',
        data: {'topic': topic},
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Failed to subscribe to topic: $e');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Failed to subscribe to topic',
        data: {
          'topic': topic,
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ [NOTIFICATION] Unsubscribed from topic: $topic');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Unsubscribed from topic',
        data: {'topic': topic},
      );
    } catch (e, stackTrace) {
      debugPrint('❌ [NOTIFICATION] Failed to unsubscribe from topic: $e');
      _debugLog.addLog(
        'NOTIFICATION_SERVICE',
        'Failed to unsubscribe from topic',
        data: {
          'topic': topic,
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
    }
  }

  /// Subscribe user to their department topic
  /// Format: department_engineering, department_it, etc.
  Future<void> subscribeToUserTopics({
    required String department,
    required String role,
  }) async {
    _debugLog.addLog(
      'NOTIFICATION_SERVICE',
      'Subscribing to user topics',
      data: {'department': department, 'role': role},
    );
    
    // Subscribe to department topic
    final deptTopic = 'department_${department.toLowerCase().replaceAll(' ', '_')}';
    await subscribeToTopic(deptTopic);
    
    // Subscribe to role topic (for role-specific notifications like admin alerts)
    final roleTopic = 'role_${role.toLowerCase().replaceAll(' ', '_')}';
    await subscribeToTopic(roleTopic);
    
    // All users subscribe to general announcements
    await subscribeToTopic('all_users');
    
    _debugLog.addLog(
      'NOTIFICATION_SERVICE',
      'User topic subscriptions complete',
      data: {
        'topics': [deptTopic, roleTopic, 'all_users'],
      },
    );
  }

  /// Unsubscribe from all topics (on logout)
  Future<void> unsubscribeFromAllTopics({
    required String department,
    required String role,
  }) async {
    _debugLog.addLog(
      'NOTIFICATION_SERVICE',
      'Unsubscribing from all user topics',
      data: {'department': department, 'role': role},
    );
    
    final deptTopic = 'department_${department.toLowerCase().replaceAll(' ', '_')}';
    await unsubscribeFromTopic(deptTopic);
    
    final roleTopic = 'role_${role.toLowerCase().replaceAll(' ', '_')}';
    await unsubscribeFromTopic(roleTopic);
    
    await unsubscribeFromTopic('all_users');
    
    _debugLog.addLog(
      'NOTIFICATION_SERVICE',
      'User topic unsubscriptions complete',
      data: {
        'topics': [deptTopic, roleTopic, 'all_users'],
      },
    );
  }
}
