import 'package:event_manager/components/bottomNavProvider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart'; // For Remote Config
import 'package:package_info_plus/package_info_plus.dart'; // For app version info
import 'package:url_launcher/url_launcher.dart'; // For launching app store

import 'shared/routes.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  tz.initializeTimeZones(); // Initialize time zones

  // Stripe setup
  Stripe.publishableKey =
      "pk_test_51POkaFDfyCqLpIlIOVS0cMwxAi2GhJxn0rSxPtHCAq31JP8Xg02GI36JImxQuIkjCgwptXPlw6u3tdVQKH6x2Jfi00ksKUywza";
  await dotenv.load(fileName: "assets/.env");
  Stripe.merchantIdentifier = 'merchant.flutter.stripe.test';
  Stripe.urlScheme = 'flutterstripe';
  await Stripe.instance.applySettings();

  // Firebase Messaging setup
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  _firebaseMessaging.requestPermission(
    alert: true,
    badge: true,
    provisional: false,
    sound: true,
  );

  _firebaseMessaging.getToken().then((token) {
    print("FCM Token: $token");
  });

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("Message received: ${message.notification?.title}");
  });

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Initialize Remote Config
  final remoteConfig = await setupRemoteConfig();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BottomTabsPageProvider()),
        Provider<FirebaseMessaging>.value(value: _firebaseMessaging),
        Provider<FirebaseRemoteConfig>.value(
            value: remoteConfig), // Provide Remote Config
      ],
      child: const MainApp(),
    ),
  );
}

// Remote Config setup function
Future<FirebaseRemoteConfig> setupRemoteConfig() async {
  final remoteConfig = FirebaseRemoteConfig.instance;

  try {
    // Set default values (optional)
    await remoteConfig.setDefaults({
      'latest_app_version': '1.0.0',
      'release_notes': 'Bug fixes and performance improvements',
      'force_update': false,
    });

    // Configure Remote Config settings
    await remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Fetch and activate Remote Config values
    await remoteConfig.fetchAndActivate();
  } catch (e) {
    print('Error setting up Remote Config: $e');
  }

  return remoteConfig;
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();

    // Initialize local notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Firebase Messaging setup
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'channel_name',
              importance: Importance.max,
              priority: Priority.high,
              showWhen: false,
              playSound: true,
            ),
          ),
        );
      }
    });

    FirebaseMessaging.instance.requestPermission();

    // Check for app updates
    checkForUpdate();
  }

  // Function to check for app updates
  Future<void> checkForUpdate() async {
    final remoteConfig =
        Provider.of<FirebaseRemoteConfig>(context, listen: false);
    final packageInfo = await PackageInfo.fromPlatform();

    String latestVersion = remoteConfig.getString('latest_app_version');
    String currentVersion = packageInfo.version;
    bool forceUpdate = remoteConfig.getBool('force_update');
    String releaseNotes = remoteConfig.getString('release_notes');

    if (latestVersion != currentVersion) {
      showDialog(
        context: context,
        barrierDismissible: !forceUpdate,
        builder: (context) => AlertDialog(
          title: Text('Update Available'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('A new version of the app is available.'),
              SizedBox(height: 10),
              Text('Release Notes:'),
              Text(releaseNotes),
            ],
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Later'),
              ),
            TextButton(
              onPressed: () {
                launchAppStore();
              },
              child: Text('Update Now'),
            ),
          ],
        ),
      );
    }
  }

  // Function to launch app store
  Future<void> launchAppStore() async {
    const url =
        'https://play.google.com/store/apps/details?id=your.package.name';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    FlutterNativeSplash.remove();
    return ScreenUtilInit(
      designSize: const Size(360, 690),
      child: MaterialApp(
        theme: ThemeData(
          textTheme: const TextTheme(
            bodyMedium: TextStyle(
              fontFamily: 'Ubuntu',
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
        routes: RouteHelper.routes(context),
        initialRoute: RouteHelper.initRoute,
      ),
    );
  }

  Future<bool> _isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }
}
