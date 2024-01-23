import 'package:flutter/material.dart';
import 'package:flutter_dialogs/flutter_dialogs.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:keycloak_wrapper/keycloak_wrapper.dart';

import '../main.dart';

class Login extends StatefulWidget {
  const Login({
    Key? key,
  }) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final storage = const FlutterSecureStorage();

  final GlobalKey<FormState> _formKey = GlobalKey();

  final FocusNode _focusNodePassword = FocusNode();
  final TextEditingController _controllerUsername = TextEditingController();
  final TextEditingController _controllerPassword = TextEditingController();
  final TextEditingController _controllerIp = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    _focusNodePassword.dispose();
    _controllerUsername.dispose();
    _controllerPassword.dispose();
    _controllerIp.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final config = KeycloakConfig(
        bundleIdentifier: 'com.vuteq',
        clientId: 'ansei-system',
        frontendUrl: 'https://sso.vuteq.co.id',
        realm: 'vuteq-indonesia',
        clientSecret: 'LMLJP5qU8VidyrtWAfczPyPGA5FAIoQw');

    await keycloakWrapper.login(config);
  }

  Future<void> save() async {
    final ip = _controllerIp.text;
    try {
      await storage.write(key: "@vuteq-ip", value: ip);
      Fluttertoast.showToast(
        msg: "IP Berhasil Disimpan",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      await Get.off(const Login());
    } catch (e) {
      Fluttertoast.showToast(
        msg: "IP Gagal Disimpan",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(height: 150),
              Image.asset(
                'assets/images/logo.png',
                width: 300,
              ),
              const SizedBox(height: 60),
              // TextFormField(
              //   controller: _controllerUsername,
              //   keyboardType: TextInputType.name,
              //   decoration: InputDecoration(
              //     labelText: "Username",
              //     prefixIcon: const Icon(Icons.person_outline),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //     enabledBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //   ),
              //   onEditingComplete: () => _focusNodePassword.requestFocus(),
              // ),
              // const SizedBox(height: 10),
              // TextFormField(
              //   controller: _controllerPassword,
              //   focusNode: _focusNodePassword,
              //   obscureText: _obscurePassword,
              //   keyboardType: TextInputType.visiblePassword,
              //   decoration: InputDecoration(
              //     labelText: "Password",
              //     prefixIcon: const Icon(Icons.password_outlined),
              //     suffixIcon: IconButton(
              //         onPressed: () {
              //           setState(() {
              //             _obscurePassword = !_obscurePassword;
              //           });
              //         },
              //         icon: _obscurePassword
              //             ? const Icon(Icons.visibility_outlined)
              //             : const Icon(Icons.visibility_off_outlined)),
              //     border: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //     enabledBorder: OutlineInputBorder(
              //       borderRadius: BorderRadius.circular(10),
              //     ),
              //   ),
              // ),
              const SizedBox(height: 60),
              Column(
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromRGBO(96, 160, 217, 1),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: login,
                    child: const Text(
                      "Login",
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20),
                    ),
                  ),
                ],
              ),
              // ElevatedButton(
              //   onPressed: () {
              //     _showInputDialog(context);
              //   },
              //   style: ElevatedButton.styleFrom(
              //     backgroundColor: Colors.redAccent, // Warna tombol 'Ganti IP Server'
              //     padding:
              //         const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              //   ),
              //   child: const Row(
              //     mainAxisAlignment: MainAxisAlignment.center,
              //     children: [
              //       Icon(
              //         Icons.settings, // Ganti dengan ikon Settings
              //         size: 20.0,
              //         color: Colors.white,
              //       ),
              //       SizedBox(width: 8), // Jarak antara ikon dan teks
              //       Text(
              //         'IP Setting',
              //         style: TextStyle(fontSize: 15.0, color: Colors.white),
              //       ),
              //     ],
              //   ),
              // ),
            ],
          ),
        ),
      ),
    );
  }

  void _showInputDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return BasicDialogAlert(
          title: const Text("Alamat IP Server"),
          content: TextFormField(
            controller: _controllerIp,
            decoration: const InputDecoration(
              hintText: "Masukkan IP Disini",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.blue, // Warna tombol tutup dialog
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Batal",
                style: TextStyle(fontSize: 15.0, color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                save();
                Navigator.pop(context); // Tutup dialog
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.green, // Warna tombol OK
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                "Simpan",
                style: TextStyle(fontSize: 15.0, color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
