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

class NewCustomWidget extends StatefulWidget {
  const NewCustomWidget({
    super.key,
    this.width,
    this.height,
    required this.initialUrl,
  });

  final double? width;
  final double? height;
  final String initialUrl;

  @override
  State<NewCustomWidget> createState() => _NewCustomWidgetState();
}

class _NewCustomWidgetState extends State<NewCustomWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FFBridge',
        onMessageReceived: (JavaScriptMessage msg) async {
          final message = msg.message;
          debugPrint("JS → Flutter: $message");

          if (message == "getLocation") {
            LocationPermission permission = await Geolocator.checkPermission();
            if (permission == LocationPermission.denied) {
              permission = await Geolocator.requestPermission();
            }

            if (permission == LocationPermission.denied ||
                permission == LocationPermission.deniedForever) {
              _sendToWeb('{"error":"Location permission denied"}');
              return;
            }

            Position pos = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            _sendToWeb('{"lat":${pos.latitude}, "lng":${pos.longitude}}');
          }

          if (message.startsWith("open:")) {
            final screen = message.split(":").last;
            if (screen == "profile") {
              Navigator.of(context).pushNamed("/profile");
            }
          }
        },
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  void _sendToWeb(String jsonPayload) {
    _controller.runJavaScript(
      'window.onNativeData && window.onNativeData($jsonPayload);',
    );
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
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
// import 'package:webviewx_plus/webviewx_plus.dart';

// class NewCustomWidget extends StatefulWidget {
//   const NewCustomWidget({
//     super.key,
//     this.width,
//     this.height,
//     required this.initialUrl,
//   });

//   final double? width;
//   final double? height;
//   final String initialUrl;

//   @override
//   State<NewCustomWidget> createState() => _NewCustomWidgetState();
// }

// class _NewCustomWidgetState extends State<NewCustomWidget> {
//   late WebViewXController _webViewXController;
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         height: widget.height,
//         width: widget.width,
//         child: WillPopScope(
//           onWillPop: () async {
//             if (await _webViewXController.canGoBack()) {
//               _webViewXController.goBack();
//               return false;
//             } else {
//               return true;
//             }
//           },
//           child: WebViewX(
//             initialContent: widget.initialUrl,
//             initialSourceType: SourceType.url,
//             width: widget.width ?? double.infinity,
//             height: widget.height ?? double.infinity,
//             onWebViewCreated: (controller) {
//               _webViewXController = controller;
//             },
//           ),
//         ));
//   }
// }
