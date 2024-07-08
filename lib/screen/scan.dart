import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get/get.dart';
import 'package:qr_bar_code_scanner_dialog/qr_bar_code_scanner_dialog.dart';
import 'package:status_alert/status_alert.dart';

import '../utils/interceptor.dart';

class Scan extends StatefulWidget {
  const Scan({super.key});

  @override
  State<Scan> createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  final _qrBarCodeScannerDialogPlugin = QrBarCodeScannerDialog();
  final storage = const FlutterSecureStorage();
  final dio = Dio(BaseOptions(baseUrl: 'https://api-ansei.vuteq.co.id/v1/'));
  // RxString qrCodeVuteq = "-".obs;

  RxString qrLabelNumberExternal = "-".obs;
  RxString qrPartNumberExternal = "-".obs;
  RxString qrPOIDExternal = "-".obs;

  RxString qrLabelNumberInternal = "-".obs;

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

  getPCCDetails(String po) async {
    try {
      dio.interceptors.add(CustomInterceptors());
      var response = await dio.get('/pokayoke/compare/get/$po',);
      // showSuccessAlert('Sukses', 'Data Riwayat Tersimpan', Colors.greenAccent);
      // Reset nilai-nilai
      // Debug: Print entire response
      debugPrint(response.data.toString());

      // Safely access nested fields
      var partNumber = response.data['PO']?['Part']?['partNumber'] ?? '-';
      var forecastId = response.data['forecastId'] ?? '-';

      debugPrint(partNumber);
      qrPartNumberExternal.value = partNumber;

      qrPOIDExternal.value = forecastId;
    } on DioException catch (e) {
      playBipBipSound();
      Vibrate.vibrateWithPauses(pauses);
      showAlert('Error', 'Label Number Tidak Ditemukan',
          Colors.redAccent);
      await reportFailed();
      qrPartNumberExternal.value = '-';
      qrPOIDExternal.value = '-';
      qrPOIDExternal.value = '-';
      qrLabelNumberInternal.value ='-';
    } finally {
      isSubmitDisabled.value = true;
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
          await getPCCDetails(qrLabelNumberExternal.value);
        } else {
          qrLabelNumberInternal.value = value['barcodeData'];
          if (qrLabelNumberExternal.value != qrLabelNumberInternal.value) {
            Vibrate.vibrateWithPauses(pauses);
            showAlert('Error', 'Label Number Tidak Cocok',
                Colors.redAccent);
            await reportFailed();
          }
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

  // getPCCDetails(kode) async {
  //   try {
  //     // Add the CustomInterceptors to the Dio instance
  //     dio.interceptors.add(CustomInterceptors());
  //     var result = await dio.get('orders/' + kode);
  //     var order = result.data['data'];
  //     qrCodeHPM.value = order['part_no'].toString();
  //     partName.value = order['part_name'].toString();
  //   } catch (e) {
  //     qrInternal.value = '-';
  //     qrCodeVuteq.value = '-';
  //     qrCodeHPM.value = '-';
  //     showAlert('Error', 'Server tidak merespon permintaan', Colors.redAccent);
  //   }
  // }

  reportFailed() async {
    try {
      final Map<String, dynamic> postData = {
        'poId': qrPOIDExternal.value,
        'labelNumber': qrLabelNumberExternal.value,
        'status': false
      };
      dio.interceptors.add(CustomInterceptors());

      await dio.post('pokayoke/compare', data: postData);

      riwayat.add({"qr": qrLabelNumberInternal.value, "date": DateTime.now()});

      // showSuccessAlert('Sukses', 'Data Riwayat Tersimpan', Colors.greenAccent);
    } on DioException catch (e) {
      debugPrint(e.response?.data.toString());
      showAlert(
          'Error',
          e.response?.data['message'] ?? 'Gagal Menghubungi Server',
          Colors.redAccent);
    } finally {
      qrPartNumberExternal.value = '-';
      qrPOIDExternal.value = '-';
      qrLabelNumberExternal.value = '-';
      qrLabelNumberInternal.value ='-';
    }
  }

  submitData() async {
    if (qrLabelNumberExternal.value == qrLabelNumberInternal.value) {
      final Map<String, dynamic> postData = {
        'poId': qrPOIDExternal.value,
        'labelNumber': qrLabelNumberExternal.value,
        'status': true
      };
      try {
        dio.interceptors.add(CustomInterceptors());

        await dio.post('pokayoke/compare', data: postData);

        showSuccessAlert(
            'Sukses', 'Data Riwayat Tersimpan', Colors.greenAccent);
        // Reset nilai-nilai
        qrPartNumberExternal.value = '-';
        qrPOIDExternal.value = '-';
        qrLabelNumberExternal.value = '-';
        qrLabelNumberInternal.value ='-';
      } on DioException catch (e) {
        // Kesalahan jaringan
        showAlert(
            'Error',
            e.response?.data['message'] ?? 'Kesalahan Jaringan/Server',
            Colors.redAccent);
        // qrCodeVuteq.value = '-';
        qrPartNumberExternal.value = '-';
        qrPOIDExternal.value = '-';
        qrLabelNumberExternal.value = '-';
        qrLabelNumberInternal.value ='-';
      } finally {
        isSubmitDisabled.value = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: const Text(
            'Scanner Part Tag Compare',
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
                              qrPartNumberExternal.value = '-';
                              qrPOIDExternal.value = '-';
                              qrLabelNumberExternal.value = '-';
                              qrLabelNumberInternal.value ='-';
                            },
                            child: const Text("Reset")),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'Part Number External',
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
                              qrPartNumberExternal.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'PO Number External',
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
                              qrPOIDExternal.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        // const SizedBox(height: 10),
                        // const Center(
                        //   child: Text(
                        //     'Part ID',
                        //     style: TextStyle(
                        //         fontSize: 22, fontWeight: FontWeight.bold),
                        //   ),
                        // ),
                        // Container(
                        //   color: Colors.grey,
                        //   width: double.infinity,
                        //   height: 60,
                        //   padding: const EdgeInsets.symmetric(horizontal: 20),
                        //   child: Center(
                        //     child: Text(
                        //       qrPartId.value,
                        //       textAlign: TextAlign.center,
                        //       style: const TextStyle(
                        //           fontSize: 22,
                        //           fontWeight: FontWeight.bold,
                        //           color: Colors.white),
                        //     ),
                        //   ),
                        // ),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'Internal Label Number',
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
                              qrLabelNumberInternal.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20),
                    InkWell(
                        onTap: (qrPOIDExternal.value != '-' &&
                                qrPartNumberExternal.value != '-' &&
                                (qrLabelNumberExternal.value ==
                                    qrLabelNumberInternal.value))
                            ? () async {
                                await submitData();
                              }
                            : null,
                        child: Container(
                          width: Get.width,
                          color:  (qrPOIDExternal.value != '-' &&
                              qrPartNumberExternal.value != '-' &&
                              (qrLabelNumberExternal.value ==
                                  qrLabelNumberInternal.value))
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
