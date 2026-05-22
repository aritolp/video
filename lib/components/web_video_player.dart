import 'package:flutter/foundation.dart'; // Añadido para detectar la plataforma web/nativa
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
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
  final FocusNode _webViewFocusNode = FocusNode(); 
  webview.InAppWebViewController? _webViewController; 
  bool _isTV = false; // Bandera para identificar Android TV

  @override
  void initState() {
    super.initState();
    _checkDeviceType();
    _keepScreenOn();
  }

  // Identifica de forma segura si la app corre en un televisor
  void _checkDeviceType() {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      // Usamos el canal de plataforma nativo para verificar la interfaz de usuario
      const MethodChannel('flutter/accessibility').invokeMethod('getUiMode').then((value) {
        // El modo de interfaz de TV en Android corresponde al valor 4
        if (value == 4) {
          setState(() {
            _isTV = true;
          });
        }
      }).catchError((_) {});
    }
  }

  @override
  void didUpdateWidget(WebVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _keepScreenOn();
    }
  }

  @override
  void dispose() {
    // Solo restauramos orientaciones móviles si no es una TV
    if (!_isTV) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }

    WakelockPlus.disable().catchError((e) => debugPrint('Error disabling wakelock: $e'));
    _webViewFocusNode.dispose();
    super.dispose();
  }

  Future<void> _keepScreenOn() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      debugPrint('Error enabling wakelock: ${e}');
    }
  }

  void _handleOrientationChange(Orientation orientation) {
    if (_webViewController == null || _isTV) return; // Si es Android TV, ignoramos el sensor físico
    
    if (orientation == Orientation.landscape) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      _webViewController?.evaluateJavascript(source: '''
        (function() {
          var video = document.querySelector('video');
          if (video && !document.fullscreenElement && !document.webkitFullscreenElement) {
            if (video.requestFullscreen) {
              video.requestFullscreen().catch(function(e) {});
            } else if (video.webkitRequestFullscreen) {
              video.webkitRequestFullscreen();
            }
          }
        })();
      ''');
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      _webViewController?.evaluateJavascript(source: '''
        (function() {
          if (document.exitFullscreen) {
            document.exitFullscreen().catch(function(e) {});
          } else if (document.webkitExitFullscreen) {
            document.webkitExitFullscreen();
          }
        })();
      ''');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String effectiveUserAgent =
        widget.userAgent ??
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36';
    final Map<String, String> headers = {};
    final String? referer = widget.referer;
    if (referer != null && referer.isNotEmpty) {
      headers['Referer'] = referer;
    }
    String effectiveUrl = widget.url;
    if (effectiveUrl.toLowerCase().contains('.ts')) {
      effectiveUrl = effectiveUrl.replaceAll(
        RegExp('\\.ts', caseSensitive: false),
        '.m3u8',
      );
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        _handleOrientationChange(orientation);

        return Focus(
          focusNode: _webViewFocusNode,
          autofocus: true,
          onKeyEvent: (node, event) {
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.backspace ||
                  event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.goBack) {
                return KeyEventResult.ignored; 
              }
            }
            return KeyEventResult.handled;
          },
          child: webview.InAppWebView(
            initialUrlRequest: webview.URLRequest(
              url: webview.WebUri(effectiveUrl),
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
              mixedContentMode: webview.MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
              safeBrowsingEnabled: false,
            ),
            onWebViewCreated: (controller) {
              _webViewController = controller; 
            },
            onEnterFullscreen: (controller) async {
              if (!_isTV) {
                await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
                await SystemChrome.setPreferredOrientations([
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
              }
            },
            onExitFullscreen: (controller) async {
              if (!_isTV) {
                await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                await SystemChrome.setPreferredOrientations([
                  DeviceOrientation.portraitUp,
                  DeviceOrientation.portraitDown,
                  DeviceOrientation.landscapeLeft,
                  DeviceOrientation.landscapeRight,
                ]);
              }
            },
            onLoadStop: (controller, url) async {
              final String setupScript = '''
                (function() {
                  if (window.customStylesApplied) return;
                  window.customStylesApplied = true;

                  var style = document.createElement("style");
                  style.innerHTML = "video { width: 100% !important; height: 100% !important; object-fit: contain !important; background: black !important; } body { margin: 0; padding: 0; background: black !important; overflow: hidden !important; } .logo, .channel-logo, #logo, [class*='logo'], [id*='logo'] { display: none !important; opacity: 0 !important; visibility: hidden !important; pointer-events: none !important; }";
                  document.head.appendChild(style);

                  function forcePlayAndFix() {
                    var videos = document.getElementsByTagName("video");
                    for (var i = 0; i < videos.length; i++) {
                      var v = videos[i];
                      v.muted = ${widget.isMuted};
                      if (v.paused) {
                        v.play().catch(function(e) {});
                      }
                    }
                    var overlays = document.querySelectorAll("div[class*='overlay'], div[id*='overlay'], div[class*='popup']");
                    for (var i = 0; i < overlays.length; i++) {
                      overlays[i].style.display = "none";
                    }
                  }
                  setInterval(forcePlayAndFix, 3500);
                })();
              ''';
              await controller.evaluateJavascript(source: setupScript);
            },
            onCreateWindow: (controller, createWindowAction) async => false,
            onReceivedHttpAuthRequest: (controller, challenge) async =>
                webview.HttpAuthResponse(action: webview.HttpAuthResponseAction.PROCEED),
            onReceivedServerTrustAuthRequest: (controller, challenge) async =>
                webview.ServerTrustAuthResponse(action: webview.ServerTrustAuthResponseAction.PROCEED),
          ),
        );
      }
    );
  }
}
