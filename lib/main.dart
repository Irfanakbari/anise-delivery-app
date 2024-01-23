import 'package:easy_splash_screen/easy_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:hpm_outgoing_app/screen/homepage.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';
import 'package:palestine_first_run/palestine_first_run.dart';

import 'screen/login.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
final keycloakWrapper = KeycloakWrapper();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await keycloakWrapper.initialize();
  keycloakWrapper.onError = (e, s) {
    print(e);

    // Display the error message inside a snackbar.
    scaffoldMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
  };
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // This widget is the root of your application.
  static const storage = FlutterSecureStorage();
  RxBool isLogin = false.obs;
  RxBool isFirst = true.obs;

  Future<void> _checkLogin() async {
    isFirst.value = await PalFirstRun.isFirstRun();
    var token = await storage.read(key: "@vuteq-token");
    if (token != null) {
      isLogin.value = true;
    }
  }

  @override
  void initState() {
    WidgetsFlutterBinding.ensureInitialized();
    super.initState();
    _checkLogin();
  }

  @override
  Widget build(BuildContext context) {
    // First time (true), then (false)
    return GetMaterialApp(
        title: 'Ansei Outgoing Scanner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: EasySplashScreen(
          logo: Image.asset(
            'assets/images/logo.png',
            width: 300,
          ),
          title: const Text(
            "Ansei Delivery Scanner",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.grey.shade400,
          showLoader: true,
          loadingText: const Text("Loading..."),
          navigator: StreamBuilder<bool>(
              initialData: false,
              stream: keycloakWrapper.authenticationStream,
              builder: (context, snapshot) =>
                  snapshot.data! ? const MyHomePage() : const Login()),
          durationInSeconds: 2,
        ));
  }
}
