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
  RxString qrInternal = "-".obs;
  final dio = Dio(BaseOptions(baseUrl: 'http://192.168.7.73:5000/v1'));
  // RxString qrCodeVuteq = "-".obs;

  RxString qrPOId = "-".obs;
  RxString qrPartNo = "-".obs;
  RxString qrPartId = "-".obs;
  RxString qrBarcodeInternal = "-".obs;
  RxString qrBarcodeExternal = "-".obs;
  RxString qrBarcodeSistem = "-".obs;

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
    final Map<String, dynamic> postData = {
      // 'po_number': qrPO.value,
      'po_id': qrPOId.value,
    };
    debugPrint(postData.toString());
    try {
      dio.interceptors.add(CustomInterceptors());
      var response = await dio.post('/pokayoke/compare/get', data: postData);
      // showSuccessAlert('Sukses', 'Data Riwayat Tersimpan', Colors.greenAccent);
      // Reset nilai-nilai
      qrPartNo.value = response.data['part_no'] ?? '-';
      qrBarcodeSistem.value = response.data['barcode'] ?? '-';
      qrPartId.value = response.data['part_id'] ?? '-';
    } on DioException catch (e) {
      debugPrint(e.response.toString());
      playBipBipSound();
      Vibrate.vibrateWithPauses(pauses);
      showAlert('Error', 'PO Number tidak sesuai dengan Part Number',
          Colors.redAccent);
      await reportFailed();
      qrPartNo.value = '-';
      // qrCodeVuteq.value = '-';
      qrPartId.value = '-';
      qrPOId.value = '-';
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
        if (qrPOId.value == '-') {
          qrPOId.value = value['barcodeData'];
          await getPCCDetails(qrPOId.value);
        } else {
          qrBarcodeInternal.value = value['barcodeData'];
        }
      } catch (e) {
        showAlert('Error', 'Kesalahan Pada Scanner', Colors.redAccent);
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    // TODO: implement dispose
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
        'po_id': qrPOId.value,
        'part_no': qrInternal.value,
      };
      debugPrint(postData.toString());
      dio.interceptors.add(CustomInterceptors());

      await dio.post('/histories/failed', data: postData);

      riwayat.add({"qr": qrInternal.value, "date": DateTime.now()});

      // showSuccessAlert('Sukses', 'Data Riwayat Tersimpan', Colors.greenAccent);
    } on DioException catch (e) {
      debugPrint(e.response?.data.toString());
      showAlert(
          'Error',
          e.response?.data['message'] ?? 'Gagal Menghubungi Server',
          Colors.redAccent);
    } finally {
      qrPOId.value = '-';
      // qrCodeVuteq.value = '-';
      qrInternal.value = '-';
    }
  }

  submitData() async {
    if (qrBarcodeInternal.value == qrBarcodeSistem.value) {
      final Map<String, dynamic> postData = {
        'po_id': qrPOId.value,
        'part_no': qrPartNo.value,
      };
      try {
        dio.interceptors.add(CustomInterceptors());

        await dio.post('/histories', data: postData);

        riwayat.add({"qr": qrInternal.value, "date": DateTime.now()});

        showSuccessAlert(
            'Sukses', 'Data Riwayat Tersimpan', Colors.greenAccent);
        // Reset nilai-nilai
        qrBarcodeInternal.value = '-';
        // qrCodeVuteq.value = '-';
        qrBarcodeSistem.value = '-';
        qrPartNo.value = '-';
        qrPOId.value = '-';
      } on DioException catch (e) {
        // Kesalahan jaringan
        showAlert(
            'Error',
            e.response?.data['message'] ?? 'Kesalahan Jaringan/Server',
            Colors.redAccent);
        // qrCodeVuteq.value = '-';
        qrBarcodeInternal.value = '-';
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
                              qrPOId.value,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                            onPressed: () {
                              _qrBarCodeScannerDialogPlugin.getScannedQrBarCode(
                                  context: context,
                                  onCode: (code) async {
                                    if (qrPOId.value == '-') {
                                      qrPOId.value = code!;
                                      await getPCCDetails(qrPOId.value);
                                    } else {
                                      qrBarcodeInternal.value = code!;
                                    }
                                  });
                            },
                            child: const Text("Click me")),
                        ElevatedButton(
                            onPressed: () async {
                              qrPOId.value = '-';
                              qrPartNo.value = '-';
                              qrPartId.value = '-';
                              qrBarcodeSistem.value = '-';
                            },
                            child: const Text("Reset")),
                        const SizedBox(height: 10),
                        const Center(
                          child: Text(
                            'Part Number',
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
                              qrPartNo.value,
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
                            'PO ID',
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
                              qrBarcodeExternal.value,
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
                              qrBarcodeInternal.value,
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
                        onTap: (qrPOId.value != '-' &&
                                qrPartNo.value != '-' &&
                                (qrBarcodeInternal.value ==
                                    qrBarcodeSistem.value))
                            ? () async {
                                await submitData();
                              }
                            : null,
                        child: Container(
                          width: Get.width,
                          color: (qrPOId.value != '-' &&
                                  qrPartNo.value != '-' &&
                                  (qrBarcodeInternal.value ==
                                      qrBarcodeSistem.value))
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
