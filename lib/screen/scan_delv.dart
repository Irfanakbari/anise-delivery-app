import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'package:status_alert/status_alert.dart';

import '../utils/interceptor.dart';

class ScanDelv extends StatefulWidget {
  const ScanDelv({super.key});

  @override
  State<ScanDelv> createState() => _ScanDelvState();
}

class _ScanDelvState extends State<ScanDelv> {
  final storage = const FlutterSecureStorage();
  final dio = Dio(BaseOptions(baseUrl: 'https://api-ansei.vuteq.co.id/v1/'));

  RxString qrLabelNumberExternal = "-".obs;

  RxList riwayat = [].obs;
  RxBool isSubmitDisabled = true.obs;
  RxBool isLoading = false.obs;
  RxBool isRed = false.obs;
  final EventChannel _eventChannel =
      const EventChannel('newland_listenToScanner');
  StreamSubscription? _streamSubscription;

  final Iterable<Duration> pauses = [
    const Duration(milliseconds: 300),
    const Duration(milliseconds: 300),
  ];

  void playBipBipSound() async {
    String bipBipSoundPath =
        "assets/error.mp3"; // Replace this with the path to your bip-bip sound file
    FlutterRingtonePlayer().play(fromAsset: bipBipSoundPath, volume: 0.5);
  }

  void showAlert(String title, String subtitle, Color backgroundColor) {
    if (mounted) {
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        title: title,
        subtitle: subtitle,
        backgroundColor: backgroundColor,
        titleOptions: StatusAlertTextConfiguration(
          style: const TextStyle(color: Colors.white),
        ),
        subtitleOptions: StatusAlertTextConfiguration(
          style: const TextStyle(color: Colors.white),
        ),
        configuration: const IconConfiguration(
          icon: Icons.error,
          color: Colors.white,
        ),
      );
    }
  }

  void showSuccessAlert(String title, String subtitle, Color backgroundColor) {
    if (mounted) {
      StatusAlert.show(
        context,
        duration: const Duration(seconds: 2),
        title: title,
        subtitle: subtitle,
        backgroundColor: backgroundColor,
        titleOptions: StatusAlertTextConfiguration(
          style: const TextStyle(color: Colors.white),
        ),
        subtitleOptions: StatusAlertTextConfiguration(
          style: const TextStyle(color: Colors.white),
        ),
        configuration: const IconConfiguration(
          icon: Icons.done,
          color: Colors.white,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _streamSubscription =
        _eventChannel.receiveBroadcastStream().listen((value) async {
      try {
        if (qrLabelNumberExternal.value == '-') {
          qrLabelNumberExternal.value = value['barcodeData'];
        }
      } catch (e) {
        showAlert('Error', 'Kesalahan Pada Scanner', Colors.redAccent);
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
    riwayat.clear();
  }

  reportFailed() async {
    try {
      final Map<String, dynamic> postData = {
        'labelDataId': qrLabelNumberExternal.value,
      };
      dio.interceptors.add(CustomInterceptors());

      await dio.post('delivery', data: postData);

      // showSuccessAlert('Sukses', 'Data Riwayat Tersimpan', Colors.greenAccent);
    } on DioException catch (e) {
      debugPrint(e.response?.data.toString());
      showAlert(
          'Error',
          e.response?.data['message'] ?? 'Gagal Menghubungi Server',
          Colors.redAccent);
    } finally {
      qrLabelNumberExternal.value = '-';
    }
  }

  submitData() async {
      try {
        final Map<String, dynamic> postData = {
          'labelDataId': qrLabelNumberExternal.value,
        };
        dio.interceptors.add(CustomInterceptors());

        await dio.post('delivery', data: postData);
      } on DioException catch (e) {
        // Kesalahan jaringan
        showAlert(
            'Error',
            e.response?.data['message'] ?? 'Kesalahan Jaringan/Server',
            Colors.redAccent);
        // qrCodeVuteq.value = '-';
        qrLabelNumberExternal.value = '-';
      } finally {
        isSubmitDisabled.value = true;
      }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text(
            'Scanner Delivery',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        body: SafeArea(
          child: Obx(
            () => Container(
              color: isRed.value
                  ? Colors.redAccent
                  : Colors.white, // Warna yang akan berkedip
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        const Center(
                          child: Text(
                            'External Label Number',
                            style: TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          color: Colors.grey,
                          width: double.infinity,
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Center(
                            child: Text(
                              qrLabelNumberExternal.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // ElevatedButton(
                        //     onPressed: () {
                        //       _qrBarCodeScannerDialogPlugin.getScannedQrBarCode(
                        //           context: context,
                        //           onCode: (code) async {
                        //             if (qrLabelNumberExternal.value == '-') {
                        //               qrLabelNumberExternal.value = code!;
                        //               await getPCCDetails(qrLabelNumberExternal.value);
                        //             } else {
                        //               qrLabelNumberInternal.value = code!;
                        //             }
                        //           });
                        //     },
                        //     child: const Text("Click me")),
                        ElevatedButton(
                            onPressed: () async {
                              qrLabelNumberExternal.value = '-';
                            },
                            child: const Text("Reset")),
                        const SizedBox(height: 10),
                      ],
                    ),
                    InkWell(
                        onTap: (qrLabelNumberExternal.isNotEmpty)
                            ? () async {
                                await submitData();
                              }
                            : null,
                        child: Container(
                          width: Get.width,
                          color: (qrLabelNumberExternal.isNotEmpty)
                              ? Colors.red
                              : Colors.grey,
                          child: const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              'Submit',
                              style:
                                  TextStyle(fontSize: 23, color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ))
                  ],
                ),
              ),
            ),
          ),
        ));
  }
}
