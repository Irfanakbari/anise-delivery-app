import 'package:flutter/material.dart';
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
  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      title: 'Ansei Compare Part Tag',
      debugShowCheckedModeBanner: false,
      home: Login(),
    );
  }
}
