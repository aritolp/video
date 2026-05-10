import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart' as webview;

@NowaGenerated()
class WebVideoPlayer extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const WebVideoPlayer({
    required this.url,
    this.userAgent,
    this.referer,
    this.isMuted = false,
    super.key,
  });

  final String url;

  final String? userAgent;

  final String? referer;

  final bool isMuted;

  @override
  State<WebVideoPlayer> createState() {
    return _WebVideoPlayerState();
  }
}

@NowaGenerated()
class _WebVideoPlayerState extends State<WebVideoPlayer> {
  webview.InAppWebViewController? controller;

  @override
  void didUpdateWidget(WebVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isMuted != widget.isMuted) {
      _applyMuteStatus();
    }
  }

  void _applyMuteStatus() {
    final ctrl = controller;
    if (ctrl != null) {
      final String muteScript =
          '        (function() {\n          var videos = document.getElementsByTagName("video");\n          for (var i = 0; i < videos.length; i++) {\n            videos[i].muted = ${widget.isMuted};\n          }\n        })();\n      ';
      ctrl.evaluateJavascript(source: muteScript);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String effectiveUserAgent =
        widget.userAgent ??
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
    final Map<String, String> headers = {};
    final String? referer = widget.referer;
    if (referer != null && referer!.isNotEmpty) {
      headers['Referer'] = referer;
    }
    return webview.InAppWebView(
      initialUrlRequest: webview.URLRequest(
        url: webview.WebUri(widget.url),
        headers: headers,
      ),
      initialSettings: webview.InAppWebViewSettings(
        javaScriptEnabled: true,
        mediaPlaybackRequiresUserGesture: false,
        allowsInlineMediaPlayback: true,
        userAgent: effectiveUserAgent,
        useWideViewPort: true,
        loadWithOverviewMode: true,
        supportZoom: false,
        transparentBackground: true,
        disableVerticalScroll: true,
        disableHorizontalScroll: true,
      ),
      onWebViewCreated: (webviewController) {
        setState(() {
          controller = webviewController;
        });
      },
      onLoadStop: (webviewController, url) async {
        final String setupScript =
            '(function() {\n            var style = document.createElement("style");\n            style.innerHTML = "video { width: 100% !important; height: 100% !important; object-fit: contain !important; background: black !important; } body { margin: 0; padding: 0; background: black !important; overflow: hidden !important; } .logo, .channel-logo, #logo, [class*=\'logo\'], [id*=\'logo\'] { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }";\n            document.head.appendChild(style);\n            \n            function forcePlayAndFix() {\n              var videos = document.getElementsByTagName("video");\n              for (var i = 0; i < videos.length; i++) {\n                var v = videos[i];\n                v.muted = ${widget.isMuted};\n                if (v.paused) {\n                  v.play().catch(function(e) {});\n                }\n                v.onpause = function(e) {\n                  if (v.paused) v.play().catch(function(e) {});\n                };\n              }\n              var overlays = document.querySelectorAll("div[class*=\'overlay\'], div[id*=\'overlay\'], div[class*=\'popup\']");\n              for (var i = 0; i < overlays.length; i++) {\n                overlays[i].style.display = "none";\n              }\n            }\n            setInterval(forcePlayAndFix, 1000);\n          })();';
        await webviewController.evaluateJavascript(source: setupScript);
      },
      onCreateWindow: (webviewController, createWindowAction) async => false,
    );
  }
}
