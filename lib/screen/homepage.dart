import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../controllers/global_controller.dart';
import 'login.dart';
import 'scan.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalController globalController =
      Get.find(); // Inisialisasi controller
  final storage = const FlutterSecureStorage();
  final dio = Dio();

  Future<void> _logout() async {
    try {
      globalController.clearGlobalVariable();
      Fluttertoast.showToast(
        msg: "Logout Berhasil",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await Get.off(const Login());
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Logout Gagal",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(),
              Column(children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 300,
                ),
                const SizedBox(height: 30),
                InkWell(
                  onTap: () => Get.to(const Scan()),
                  child: Container(
                    width: Get.width,
                    color: Colors.red,
                    child: const Padding(
                      padding: EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.scanner, // Ganti dengan ikon yang diinginkan
                            color: Colors.white,
                            size: 24.0,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Scan Pokayoke',
                            style: TextStyle(
                              fontSize: 22.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                InkWell(
                  onTap: () => Get.to(const Scan()),
                  child: Container(
                    width: Get.width,
                    color: Colors.green,
                    child: const Padding(
                      padding: EdgeInsets.all(15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.scanner, // Ganti dengan ikon yang diinginkan
                            color: Colors.white,
                            size: 24.0,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Scan Delivery',
                            style: TextStyle(
                              fontSize: 22.0,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
              ]),
              Column(children: [
                ElevatedButton(
                  onPressed: () => _logout(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Warna tombol 'Scanner Masuk'
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons
                            .logout, // Ganti dengan ikon logout yang diinginkan
                        size: 20.0,
                        color: Colors.white,
                      ),
                      SizedBox(width: 8), // Jarak antara ikon dan teks
                      Text(
                        'Logout',
                        style: TextStyle(fontSize: 15.0, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ])
            ],
          ),
        ),
      ),
    );
  }
}
