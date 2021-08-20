import 'dart:async';
import 'dart:convert';
import 'package:chat_app/models/User.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  await Firebase.initializeApp();
  print('Handling a background message ${message.messageId}');
}

/// Create a [AndroidNotificationChannel] for heads up notifications
AndroidNotificationChannel channel;

/// Initialize the [FlutterLocalNotificationsPlugin] package.
FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

class NotificationHelper {
  static final NotificationHelper _singleton = NotificationHelper._internal();
  factory NotificationHelper() {
    return _singleton;
  }
  NotificationHelper._internal();
  initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  listen() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                icon: '@mipmap/ic_launcher',
              ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
    });
  }

  Future<void> bildirimGonder(
      {String message,
      Userr senderUser,
      String token,
      String chatRoomid,
      bool isAdminMessage = false,
      String adminMessssageTitle}) async {
    if (token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }

    try {
      var k = await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAAMrOkRJE:APA91bE-8YMm-uWd8H4xqNtE5FJgPQ1Z1HNEDuDi0Mw5p8iPy8o6K0S98rj98Yk7xGGStpCGqS72dwdMSwNgQGENc5PWJ7AxrZ0XF6r9GVmh4m0Yfh7kTPUNjp1QHQ-7ufoe6nJUPEOO'
        },
        body: jsonEncode({
          'to': token,
          'data': {
            'message': '$message',
            'title': '${senderUser.name}',
            'senderId': '${senderUser.userid}',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK'
          },
          'notification': {
            'title': '${senderUser.name}',
            'body': '$message',
          },
        }),
      );

      print('FCM request for device sent!');
      print(k.reasonPhrase);
    } catch (e) {
      print(e);
    }
  }
}
/*
class NotificationHandler2 {
  FirebaseMessaging fcm = FirebaseMessaging.instance;

  Future<dynamic> backgroundMessageHandler(RemoteMessage message) async {
    print("_backgroundMessageHandler");
    if (message.data.isNotEmpty) {
      // Handle data message
      final dynamic data = message.data;
      print("_backgroundMessageHandler data: $data");
      //NotificationHandler.showNotification(message.data);
    }
  }

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final NotificationHandler _singleton = NotificationHandler._internal();
  factory NotificationHandler() {
    return _singleton;
  }
  NotificationHandler._internal();

  static BuildContext notifyContext;
  initializeFCMNotification(BuildContext context) async {
    notifyContext = context;
    fcm.subscribeToTopic("adminMessage");
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettingsIOS = IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid, iOS: initializationSettingsIOS);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);
  }

  static void showNotification(Map<String, dynamic> message,
      {BuildContext ctx}) async {
    if (message == null) return;
    notifyContext = ctx;
    var mesaj = Person(
      name: message["title"],
      key: '1',
      //icon: userURLPath,
    );
    var mesajStyle = MessagingStyleInformation(mesaj,
        messages: [Message(message["message"], DateTime.now(), mesaj)]);

    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        '1234', 'Yeni Mesaj', 'your channel description',
        styleInformation: mesajStyle,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, message["title"], message["message"], platformChannelSpecifics,
        payload: jsonEncode(message));
  }

  Future onSelectNotification(String payload) async {
    print("onselectNotification");
    if (payload != null) {
      //  Map<String, dynamic> gelenBildirim = await jsonDecode(payload);

    }

    return Future<void>.value();
  }

  static Future onDidReceiveLocalNotification(
      int id, String title, String body, String payload) {
    return Future<void>.value();
  }
}

class TestNotify2 {
  FirebaseMessaging fcm = FirebaseMessaging.instance;

  Future<dynamic> backgroundMessageHandler(RemoteMessage message) async {
    print("_backgroundMessageHandler");
    if (message.data.isNotEmpty) {
      // Handle data message
      final dynamic data = message.data;
      print("_backgroundMessageHandler data: $data");
      //NotificationHandler.showNotification(message.data);
    }
  }

  AndroidNotificationChannel channel;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  initialize() async {
    // Set the background messaging handler early on, as a named top-level function
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);

    channel = const AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // title
      'This channel is used for important notifications.', // description
      importance: Importance.high,
    );

    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    /// Create an Android Notification Channel.
    ///
    /// We use this channel in the `AndroidManifest.xml` file to override the
    /// default FCM channel to enable heads up notifications.
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    /// Update the iOS foreground notification presentation options to allow
    /// heads up notifications.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  initializeFCMNotification(BuildContext context) async {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      if (message != null) {
        /*  Navigator.pushNamed(context, '/message',
            arguments: MessageArguments(message, true));*/
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification notification = message.notification;
      AndroidNotification android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
            notification.hashCode,
            notification.title,
            notification.body,
            NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channel.description,
                icon: 'launch_background',
              ),
            ));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      /*  Navigator.pushNamed(context, '/message',
          arguments: MessageArguments(message, true));*/
    });
  }

  Future<void> bildirimGonder(
      {String message,
      Userr senderUser,
      String token,
      String chatRoomid,
      bool isAdminMessage = false,
      String adminMessssageTitle}) async {
    if (token == null) {
      print('Unable to send FCM message, no token exists.');
      return;
    }

    try {
      var k = await http.post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=AAAAFyYOHJw:APA91bEhw0-kil8CB7MUwdHdT46JkCI6f-WJa2gIyCp0DHNRYZlrtJv3THpBk3J15YVqjrSkRtE4yAOFmDB09w2EpWhdm4mmVWa85N_6VQnqZblWQSQPWh01YEG-Bv5cBN7PQ7eS1w6V'
        },
        body: jsonEncode({
          'to': token,
          'data': {
            'message': '$message',
            'title': '${senderUser.name}',
            'senderId': '${senderUser.userid}',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK'
          },
          'notification': {
            'title': '${senderUser.name}',
            'body': '$message',
          },
        }),
      );

      print('FCM request for device sent!');
      print(k.reasonPhrase);
    } catch (e) {
      print(e);
    }
  }

  Future<void> onActionSelected(String value) async {
    switch (value) {
      case 'subscribe':
        {
          print(
              'FlutterFire Messaging Example: Subscribing to topic "fcm_test".');
          await FirebaseMessaging.instance.subscribeToTopic('fcm_test');
          print(
              'FlutterFire Messaging Example: Subscribing to topic "fcm_test" successful.');
        }
        break;
      case 'unsubscribe':
        {
          print(
              'FlutterFire Messaging Example: Unsubscribing from topic "fcm_test".');
          await FirebaseMessaging.instance.unsubscribeFromTopic('fcm_test');
          print(
              'FlutterFire Messaging Example: Unsubscribing from topic "fcm_test" successful.');
        }
        break;
      case 'get_apns_token':
        {}
        break;
      default:
        break;
    }
  }
}
*/