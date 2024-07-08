import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

import 'screen/login.dart';

final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  Future<void> _checkLogin() async {
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
        title: 'Ansei Scanner',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const Login());
  }
}
