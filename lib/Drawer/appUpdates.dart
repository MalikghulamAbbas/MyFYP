import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdatesPage extends StatefulWidget {
  @override
  _AppUpdatesPageState createState() => _AppUpdatesPageState();
}

class _AppUpdatesPageState extends State<AppUpdatesPage> {
  @override
  void initState() {
    super.initState();
    checkForUpdate(); // Check for updates when the page loads
  }

  Future<void> checkForUpdate() async {
    final remoteConfig = await setupRemoteConfig();
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
          title: Text(
            'Update Available',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version of the app is available.',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Release Notes:',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
              Text(
                releaseNotes,
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ],
          ),
          actions: [
            if (!forceUpdate)
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Later',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black,
                  ),
                ),
              ),
            TextButton(
              onPressed: () {
                launchAppStore();
              },
              child: Text(
                'Update Now',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

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
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final buttonColor = isDarkTheme ? Colors.redAccent : Colors.red;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Updates',
          style: TextStyle(color: textColor),
        ),
        backgroundColor: Colors.red,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: isDarkTheme ? Colors.black : Colors.white,
      body: Center(
        child: GestureDetector(
          onTap: () => checkForUpdate(),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            decoration: BoxDecoration(
              color: buttonColor,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              'Check for Updates',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<FirebaseRemoteConfig> setupRemoteConfig() async {
  final FirebaseRemoteConfig remoteConfig = FirebaseRemoteConfig.instance;

  await remoteConfig.setConfigSettings(
    RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      minimumFetchInterval: const Duration(hours: 1),
    ),
  );

  await remoteConfig.fetchAndActivate();
  return remoteConfig;
}
