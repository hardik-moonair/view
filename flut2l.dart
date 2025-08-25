// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/custom_code/widgets/index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:webview_flutter/webview_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
// import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:call_log/call_log.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

class FieldForceWebView extends StatefulWidget {
  const FieldForceWebView({
    super.key,
    this.width,
    this.height,
    required this.initialUrl,
  });

  final double? width;
  final double? height;
  final String initialUrl;

  @override
  State<FieldForceWebView> createState() => _FieldForceWebViewState();
}

class _FieldForceWebViewState extends State<FieldForceWebView> {
  late final WebViewController _controller;
  final ImagePicker _imagePicker = ImagePicker();
  QRViewController? _qrController;
  final GlobalKey _qrKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'NativeApp',
        onMessageReceived: (JavaScriptMessage msg) async {
          await _handleMessage(msg.message);
        },
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<void> _handleMessage(String message) async {
    debugPrint("JS → Flutter: $message");

    try {
      final Map<String, dynamic> data = jsonDecode(message);
      final String action = data['action'] ?? message;
      final Map<String, dynamic> params = data['params'] ?? {};

      switch (action) {
        case 'GET_LOCATION':
          await _handleGetLocation();
          break;
        case 'CAPTURE_PHOTO':
          await _handleCapturePhoto(params);
          break;
        // case 'SCAN_QR':
        //   await _handleScanQR();
        //   break;
        // case 'SCAN_BARCODE':
        //   await _handleScanBarcode();
        //   break;
        case 'MAKE_CALL':
          await _handleMakeCall(params['number']);
          break;
        case 'GET_CALL_LOGS':
          await _handleGetCallLogs(params['days'] ?? 7);
          break;
        case 'SHOW_TOAST':
          _handleShowToast(params['message']);
          break;
        case 'UPLOAD_FILE':
          await _handleUploadFile(params['base64'], params['filename']);
          break;
        case 'DOWNLOAD_FILE':
          await _handleDownloadFile(params['url'], params['filename']);
          break;
        case 'GET_DEVICE_INFO':
          await _handleGetDeviceInfo();
          break;
        case 'STORAGE_SET':
          await _handleStorageSet(params['key'], params['value']);
          break;
        case 'STORAGE_GET':
          await _handleStorageGet(params['key']);
          break;
        case 'GET_NETWORK_STATUS':
          await _handleGetNetworkStatus();
          break;

        // Legacy support for simple messages
        case 'getLocation':
          await _handleGetLocation();
          break;
        default:
          if (message.startsWith("open:")) {
            final screen = message.split(":").last;
            if (screen == "profile") {
              Navigator.of(context).pushNamed("/profile");
            }
          }
      }
    } catch (e) {
      // Handle simple string messages or malformed JSON
      if (message == 'getLocation') {
        await _handleGetLocation();
      } else {
        _sendErrorToWeb('INVALID_MESSAGE', 'Unable to parse message: $message');
      }
    }
  }

  // Location Services
  Future<void> _handleGetLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _sendErrorToWeb(
            'LOCATION_PERMISSION_DENIED', 'Location permission denied');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final response = {
        'action': 'GET_LOCATION',
        'data': {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'timestamp': position.timestamp?.millisecondsSinceEpoch,
        }
      };

      _sendToWeb(jsonEncode(response));
    } catch (e) {
      _sendErrorToWeb('LOCATION_ERROR', e.toString());
    }
  }

  // Camera/Photo Functions
  Future<void> _handleCapturePhoto(Map<String, dynamic> params) async {
    try {
      final PermissionStatus permission = await Permission.camera.request();
      if (!permission.isGranted) {
        _sendErrorToWeb('CAMERA_PERMISSION_DENIED', 'Camera permission denied');
        return;
      }

      final ImageSource source = params['source'] == 'gallery'
          ? ImageSource.gallery
          : ImageSource.camera;

      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: ((params['quality'] ?? 0.8) * 100).round(),
        maxWidth: params['maxWidth']?.toDouble(),
        maxHeight: params['maxHeight']?.toDouble(),
      );

      if (image != null) {
        final Uint8List imageBytes = await image.readAsBytes();
        final String base64String = base64Encode(imageBytes);
        final File imageFile = File(image.path);

        final response = {
          'action': 'CAPTURE_PHOTO',
          'data': {
            'base64': base64String,
            'path': image.path,
            'size': imageBytes.length,
            'name': image.name,
          }
        };

        _sendToWeb(jsonEncode(response));
      } else {
        _sendErrorToWeb('PHOTO_CANCELLED', 'Photo capture was cancelled');
      }
    } catch (e) {
      _sendErrorToWeb('PHOTO_ERROR', e.toString());
    }
  }

  // QR/Barcode Scanner
  // Future<void> _handleScanQR() async {
  //   await _showQRScanner();
  // }

  // Future<void> _handleScanBarcode() async {
  //   await _showQRScanner(); // Same scanner can handle both
  // }

  // Future<void> _showQRScanner() async {
  //   final result = await showDialog<String>(
  //     context: context,
  //     builder: (context) => Dialog(
  //       child: Container(
  //         height: 400,
  //         child: QRView(
  //           key: _qrKey,
  //           onQRViewCreated: (QRViewController controller) {
  //             _qrController = controller;
  //             controller.scannedDataStream.listen((scanData) {
  //               Navigator.of(context).pop(scanData.code);
  //             });
  //           },
  //         ),
  //       ),
  //     ),
  //   );

  //   if (result != null) {
  //     final response = {
  //       'action': 'SCAN_QR',
  //       'data': {
  //         'data': result,
  //         'format': 'QR_CODE', // Could be enhanced to detect format
  //         'timestamp': DateTime.now().millisecondsSinceEpoch,
  //       }
  //     };
  //     _sendToWeb(jsonEncode(response));
  //   } else {
  //     _sendErrorToWeb('SCAN_CANCELLED', 'Scan was cancelled');
  //   }
  // }

  // Call Functions
  Future<void> _handleMakeCall(String? phoneNumber) async {
    if (phoneNumber == null) {
      _sendErrorToWeb('INVALID_PHONE', 'Phone number is required');
      return;
    }

    try {
      final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
      await launchUrl(launchUri);

      final response = {
        'action': 'MAKE_CALL',
        'data': {'success': true}
      };
      _sendToWeb(jsonEncode(response));
    } catch (e) {
      _sendErrorToWeb('CALL_ERROR', e.toString());
    }
  }

  Future<void> _handleGetCallLogs(int days) async {
    try {
      final PermissionStatus permission = await Permission.phone.request();
      if (!permission.isGranted) {
        _sendErrorToWeb('PHONE_PERMISSION_DENIED', 'Phone permission denied');
        return;
      }

      final DateTime from = DateTime.now().subtract(Duration(days: days));
      final Iterable<CallLogEntry> entries = await CallLog.query(
        dateFrom: from.millisecondsSinceEpoch,
      );

      final List<Map<String, dynamic>> callLogs = entries
          .map((entry) => {
                'number': entry.number,
                'name': entry.name,
                'duration': entry.duration,
                'timestamp': entry.timestamp,
                'type': _getCallType(entry.callType),
              })
          .toList();

      final response = {'action': 'GET_CALL_LOGS', 'data': callLogs};
      _sendToWeb(jsonEncode(response));
    } catch (e) {
      _sendErrorToWeb('CALL_LOG_ERROR', e.toString());
    }
  }

  String _getCallType(CallType? type) {
    switch (type) {
      case CallType.incoming:
        return 'incoming';
      case CallType.outgoing:
        return 'outgoing';
      case CallType.missed:
        return 'missed';
      default:
        return 'unknown';
    }
  }

  // File Management
  Future<void> _handleUploadFile(String? base64Data, String? filename) async {
    if (base64Data == null || filename == null) {
      _sendErrorToWeb('INVALID_FILE_DATA', 'Base64 data and filename required');
      return;
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDir.path}/$filename';
      final Uint8List bytes = base64Decode(base64Data);
      final File file = File(filePath);
      await file.writeAsBytes(bytes);

      final response = {
        'action': 'UPLOAD_FILE',
        'data': {
          'success': true,
          'path': filePath,
          'size': bytes.length,
        }
      };
      _sendToWeb(jsonEncode(response));
    } catch (e) {
      _sendErrorToWeb('UPLOAD_ERROR', e.toString());
    }
  }

  Future<void> _handleDownloadFile(String? url, String? filename) async {
    if (url == null || filename == null) {
      _sendErrorToWeb('INVALID_DOWNLOAD_DATA', 'URL and filename required');
      return;
    }

    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String filePath = '${appDir.path}/$filename';

      final Dio dio = Dio();
      await dio.download(url, filePath);

      final response = {
        'action': 'DOWNLOAD_FILE',
        'data': {
          'success': true,
          'path': filePath,
        }
      };
      _sendToWeb(jsonEncode(response));
    } catch (e) {
      _sendErrorToWeb('DOWNLOAD_ERROR', e.toString());
    }
  }

  // Device Info
  Future<void> _handleGetDeviceInfo() async {
    try {
      final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      Map<String, dynamic> deviceData = {};

      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceData = {
          'deviceId': androidInfo.id,
          'model': androidInfo.model,
          'platform': 'android',
          'version': androidInfo.version.release,
          'manufacturer': androidInfo.manufacturer,
        };
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceData = {
          'deviceId': iosInfo.identifierForVendor,
          'model': iosInfo.model,
          'platform': 'ios',
          'version': iosInfo.systemVersion,
          'manufacturer': 'Apple',
        };
      }

      final List<ConnectivityResult> connectivityResults =
          await Connectivity().checkConnectivity();
      final ConnectivityResult connectivity = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;
      deviceData.addAll({
        'networkType': _getNetworkType(connectivity),
        'isOnline': connectivity != ConnectivityResult.none,
        'appVersion': '1.0.0', // You might want to get this dynamically
      });

      final response = {'action': 'GET_DEVICE_INFO', 'data': deviceData};
      _sendToWeb(jsonEncode(response));
    } catch (e) {
      _sendErrorToWeb('DEVICE_INFO_ERROR', e.toString());
    }
  }

  String _getNetworkType(ConnectivityResult connectivity) {
    switch (connectivity) {
      case ConnectivityResult.wifi:
        return 'wifi';
      case ConnectivityResult.mobile:
        return 'cellular';
      default:
        return 'none';
    }
  }

  // Storage Functions
  Future<void> _handleStorageSet(String? key, dynamic value) async {
    if (key == null) {
      _sendErrorToWeb('INVALID_STORAGE_KEY', 'Storage key is required');
      return;
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String jsonValue = jsonEncode(value);
      await prefs.setString(key, jsonValue);

      final response = {
        'action': 'STORAGE_SET',
        'data': {'success': true}
      };
      _sendToWeb(jsonEncode(response));
    } catch (e) {
      _sendErrorToWeb('STORAGE_SET_ERROR', e.toString());
    }
  }

  Future<void> _handleStorageGet(String? key) async {
    if (key == null) {
      _sendErrorToWeb('INVALID_STORAGE_KEY', 'Storage key is required');
      return;
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? jsonValue = prefs.getString(key);
      dynamic value;

      if (jsonValue != null) {
        value = jsonDecode(jsonValue);
      }

      final response = {
        'action': 'STORAGE_GET',
        'data': {
          'success': true,
          'data': value,
        }
      };
      _sendToWeb(jsonEncode(response));
    } catch (e) {
      _sendErrorToWeb('STORAGE_GET_ERROR', e.toString());
    }
  }

  // Network Status
  Future<void> _handleGetNetworkStatus() async {
    try {
      final List<ConnectivityResult> connectivityResults =
          await Connectivity().checkConnectivity();
      final ConnectivityResult connectivity = connectivityResults.isNotEmpty
          ? connectivityResults.first
          : ConnectivityResult.none;

      final response = {
        'action': 'GET_NETWORK_STATUS',
        'data': {
          'type': _getNetworkType(connectivity),
          'isOnline': connectivity != ConnectivityResult.none,
        }
      };
      _sendToWeb(jsonEncode(response));
    } catch (e) {
      _sendErrorToWeb('NETWORK_STATUS_ERROR', e.toString());
    }
  }

  // Toast Messages
  void _handleShowToast(String? message) {
    if (message != null) {
      Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  // Helper Functions
  void _sendToWeb(String jsonPayload) {
    _controller.runJavaScript(
      'window.onNativeResponse && window.onNativeResponse($jsonPayload);',
    );
  }

  void _sendErrorToWeb(String errorCode, String errorMessage) {
    final response = {
      'error': true,
      'code': errorCode,
      'message': errorMessage,
    };
    _sendToWeb(jsonEncode(response));
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _qrController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width ?? double.infinity,
      height: widget.height ?? double.infinity,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: WebViewWidget(controller: _controller),
      ),
    );
  }
}
