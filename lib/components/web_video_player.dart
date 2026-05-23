import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Añadido para capturar eventos de teclado
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
  final FocusNode _webViewFocusNode = FocusNode(); // Nodo de control para Android TV

  @override
  void initState() {
    super.initState();
    _keepScreenOn();
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
    // CORRECCIÓN 2: Liberar la pantalla y limpiar el nodo de foco obligatoriamente
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

    // CORRECCIÓN 3: Blindamos el WebView con un Focus interceptor para evitar que se trague el botón "Atrás" en TV
    return Focus(
      focusNode: _webViewFocusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Si el usuario en Android TV presiona "Atrás", "Escape" o "Backspace", permitimos que Flutter lo maneje
          if (event.logicalKey == LogicalKeyboardKey.backspace ||
              event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.goBack) {
            return KeyEventResult.ignored; // Ignorado aquí significa que sube al Navigator de Flutter para cerrar la pantalla
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
        onWebViewCreated: (controller) {},
        onLoadStop: (controller, url) async {
          // CORRECCIÓN 1: JavaScript optimizado. Los estilos se inyectan una sola vez. 
          // El bucle ahora es de 3.5 segundos y no consume CPU si el video ya está reproduciendo.
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
              // Intervalo subido a 3500ms para cuidar el procesador de dispositivos móviles y de TV
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
}
