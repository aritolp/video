import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tvplus/player_status.dart';
import 'dart:async';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:tvplus/components/web_video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:flutter/services.dart';

@NowaGenerated()
class HlsVideoPlayer extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const HlsVideoPlayer({
    required this.url,
    this.userAgent,
    this.referer,
    this.onStatusChanged,
    this.logoUrl,
    super.key,
  });

  final String url;

  final String? userAgent;

  final String? referer;

  final void Function(PlayerStatus status, String message)? onStatusChanged;

  final String? logoUrl;

  @override
  State<HlsVideoPlayer> createState() {
    return _HlsVideoPlayerState();
  }
}

@NowaGenerated()
class _HlsVideoPlayerState extends State<HlsVideoPlayer> {
  VideoPlayerController? _videoPlayerController;

  bool _isInitialized = false;

  String? _errorMessage;

  int _retryCount = 0;

  PlayerStatus _currentStatus = PlayerStatus.connecting;

  Timer? _retryTimer;

  bool _showControls = true;

  Timer? _controlsTimer;

  final List<String> _codecs = ['Auto', 'Software', 'Hardware'];

  int _currentCodecIndex = 0;

  final FocusNode _playPauseNode = FocusNode();

  final FocusNode _codecNode = FocusNode();

  final FocusNode _rewindNode = FocusNode();

  final FocusNode _forwardNode = FocusNode();

  final FocusNode _audioNode = FocusNode();

  double _brightness = 0.5;

  double _volume = 0.5;

  bool _showVolumeIndicator = false;

  bool _showBrightnessIndicator = false;

  Timer? _overlayTimer;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(HlsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retryCount = 0;
      _currentStatus = PlayerStatus.connecting;
      _initializePlayer();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _handleError(String error) {
    if (_currentStatus == PlayerStatus.webFallback) {
      return;
    }
    if (_retryCount < 2) {
      _retryCount++;
      _updateStatus(PlayerStatus.retrying, 'Reconectando...');
      _retryTimer?.cancel();
      _retryTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          _initializePlayer();
        }
      });
    } else {
      _updateStatus(PlayerStatus.webFallback, 'Modo Alternativo');
    }
  }

  void _listener() {
    if (!mounted || _videoPlayerController == null) {
      return;
    }
    final value = _videoPlayerController?.value;
    if (value!.hasError) {
      _handleError(value?.errorDescription ?? 'Error desconocido');
    } else if (value!.isPlaying) {
      if (_currentStatus != PlayerStatus.playing) {
        _updateStatus(PlayerStatus.playing, 'En vivo');
        _retryCount = 0;
      }
    }
    setState(() {});
  }

  void _switchCodec() {
    _currentCodecIndex = (_currentCodecIndex + 1) % _codecs.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Procesamiento: ${_codecs[_currentCodecIndex]}'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red.withValues(alpha: 0.8),
      ),
    );
    _initializePlayer();
    _startControlsTimer();
  }

  void _updateStatus(PlayerStatus status, String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _currentStatus = status;
    });
    if (status == PlayerStatus.webFallback) {
      _videoPlayerController?.dispose();
      _videoPlayerController = null;
    }
    widget.onStatusChanged?.call(status, message);
  }

  String _formatDuration(Duration duration) {
    @NowaGenerated()
    String twoDigits(int n) {
      return n.toString().padLeft(2, '0');
    }

    final minutes = twoDigits(duration.inMinutes.remainder(60).toInt());
    final seconds = twoDigits(duration.inSeconds.remainder(60).toInt());
    return '${twoDigits(duration.inHours)}:${minutes}:${seconds}';
  }

  Future<void> _seekRelative(Duration offset) async {
    if (_videoPlayerController == null ||
        !_videoPlayerController!.value.isInitialized) {
      return;
    }
    final newPosition = _videoPlayerController!.value.position + offset;
    final duration = _videoPlayerController!.value.duration;
    if (newPosition < Duration.zero) {
      await _videoPlayerController?.seekTo(Duration.zero);
    } else if (newPosition > duration) {
      await _videoPlayerController?.seekTo(duration);
    } else {
      await _videoPlayerController?.seekTo(newPosition);
    }
    _startControlsTimer();
  }

  Future<void> _showAudioMenu() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cambiando pista de audio secundaria...'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.blue.withValues(alpha: 0.8),
      ),
    );
    _initializePlayer();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: _currentStatus == PlayerStatus.webFallback
          ? WebVideoPlayer(
              key: ValueKey('web_${widget.url}'),
              url: widget.url,
              userAgent: widget.userAgent,
              referer: widget.referer,
              isMuted: false,
            )
          : _buildNativePlayer(),
    );
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _controlsTimer?.cancel();
    _videoPlayerController?.removeListener(_listener);
    _videoPlayerController?.dispose();
    WakelockPlus.disable();
    _playPauseNode.dispose();
    _codecNode.dispose();
    _rewindNode.dispose();
    _forwardNode.dispose();
    _audioNode.dispose();
    super.dispose();
  }

  void _onVerticalDragUpdate(DragUpdateDetails details, double width) {
    if (details.localPosition.dx < width / 2) {
      _updateBrightness(-details.primaryDelta! / 200);
    } else {
      _updateVolume(-details.primaryDelta! / 200);
    }
  }

  Future<void> _updateBrightness(double delta) async {
    _brightness = (_brightness + delta).clamp(0.0, 1.0);
    try {
      await ScreenBrightness().setScreenBrightness(_brightness);
    } catch (e) {
      debugPrint('Error setting brightness: ${e}');
    }
    setState(() {
      _showBrightnessIndicator = true;
      _showVolumeIndicator = false;
    });
    _resetOverlayTimer();
  }

  Future<void> _updateVolume(double delta) async {
    _volume = (_volume + delta).clamp(0.0, 1.0);
    VolumeController().setVolume(_volume);
    setState(() {
      _showVolumeIndicator = true;
      _showBrightnessIndicator = false;
    });
    _resetOverlayTimer();
  }

  void _resetOverlayTimer() {
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showVolumeIndicator = false;
          _showBrightnessIndicator = false;
        });
      }
    });
  }

  Widget _buildGestureIndicator(IconData icon, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20.0),
          const SizedBox(width: 8.0),
          SizedBox(
            width: 100.0,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white24,
              color: color,
              minHeight: 4.0,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
      if (MediaQuery.of(context).navigationMode == NavigationMode.directional) {
        _playPauseNode.requestFocus();
      }
    }
  }

  Widget _buildNativePlayer() {
    final bool hasError =
        _errorMessage != null ||
        (_videoPlayerController?.value.hasError ?? false);
    final String? logoUrl = widget.logoUrl;
    final bool isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (!_showControls &&
              (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                  event.logicalKey == LogicalKeyboardKey.arrowDown ||
                  event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                  event.logicalKey == LogicalKeyboardKey.arrowRight ||
                  event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.accept)) {
            _toggleControls();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.backspace ||
              event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.goBack) {
            if (_showControls) {
              setState(() => _showControls = false);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (logoUrl != null && (!_isInitialized || hasError))
            Positioned.fill(
              child: Image.network(
                logoUrl,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.5),
                colorBlendMode: BlendMode.darken,
              ),
            ),
          if (_videoPlayerController != null && _isInitialized && !hasError)
            Center(
              child: AspectRatio(
                aspectRatio: _videoPlayerController!.value.aspectRatio,
                child: VideoPlayer(_videoPlayerController!),
              ),
            ),
          if (_isInitialized && !hasError) _buildCustomControls(),
          if (_currentStatus == PlayerStatus.retrying ||
              _currentStatus == PlayerStatus.connecting)
            Positioned(
              bottom: 80.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 6.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Text(
                  _currentStatus == PlayerStatus.retrying
                      ? 'Reconectando...'
                      : 'Conectando...',
                  style: const TextStyle(color: Colors.white, fontSize: 10.0),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _initializePlayer() async {
    if (_currentStatus == PlayerStatus.webFallback) {
      return;
    }
    setState(() {
      _isInitialized = false;
      _errorMessage = null;
    });
    try {
      final Duration? lastPosition = _videoPlayerController?.value.position;
      _videoPlayerController?.dispose();
      await WakelockPlus.enable();
      final Map<String, String> headers = {
        'User-Agent':
            widget.userAgent ??
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };
      final String? currentReferer = widget.referer;
      if (currentReferer != null && currentReferer!.isNotEmpty) {
        headers['Referer'] = currentReferer;
      }
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: headers,
        videoPlayerOptions: VideoPlayerOptions(
          allowBackgroundPlayback: true,
          mixWithOthers: true,
        ),
      );
      await _videoPlayerController?.initialize();
      _videoPlayerController?.addListener(_listener);
      await _videoPlayerController?.setVolume(1.0);
      if (lastPosition != null && lastPosition! > Duration.zero) {
        await _videoPlayerController?.seekTo(lastPosition);
      }
      _videoPlayerController?.play();
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _showControls = true;
        });
        _startControlsTimer();
        if (MediaQuery.of(context).navigationMode ==
            NavigationMode.directional) {
          _playPauseNode.requestFocus();
        }
      }
    } catch (e) {
      _handleError(e.toString());
    }
  }

  Widget _controlButton({
    required FocusNode node,
    required IconData icon,
    required void Function() onPressed,
    double size = 32,
  }) {
    return Focus(
      focusNode: node,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select ||
                event.logicalKey == LogicalKeyboardKey.accept)) {
          onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        padding: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: node.hasFocus
              ? Colors.white.withValues(alpha: 0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: node.hasFocus ? Colors.white : Colors.transparent,
            width: 2.0,
          ),
          boxShadow: [
            if (node.hasFocus)
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.2),
                blurRadius: 8.0,
                spreadRadius: 1.0,
              ),
          ],
        ),
        child: IconButton(
          constraints: const BoxConstraints(),
          padding: const EdgeInsets.all(6.0),
          icon: Icon(icon, color: Colors.white, size: size),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildCustomControls() {
    final bool isPlaying = _videoPlayerController?.value.isPlaying ?? false;
    final Duration position =
        _videoPlayerController?.value.position ?? Duration.zero;
    final Duration duration =
        _videoPlayerController?.value.duration ?? Duration.zero;
    final bool isVod = duration > Duration.zero;
    final String statusLabel = isVod ? 'VIDEO' : 'EN VIVO';
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onVerticalDragUpdate: (details) => _onVerticalDragUpdate(
              details,
              MediaQuery.of(context).size.width,
            ),
            onTap: _toggleControls,
          ),
          if (_showVolumeIndicator || _showBrightnessIndicator)
            Center(
              child: _showVolumeIndicator
                  ? _buildGestureIndicator(
                      Icons.volume_up,
                      _volume,
                      Colors.blue,
                    )
                  : _buildGestureIndicator(
                      Icons.brightness_6,
                      _brightness,
                      Colors.orange,
                    ),
            ),
          AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                color: Colors.black45,
                child: Column(
                  children: [
                    const Spacer(),
                    FocusTraversalGroup(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isVod)
                            _controlButton(
                              node: _rewindNode,
                              icon: Icons.replay_10_rounded,
                              size: 24.0,
                              onPressed: () =>
                                  _seekRelative(const Duration(seconds: -10)),
                            ),
                          const SizedBox(width: 12.0),
                          _controlButton(
                            node: _playPauseNode,
                            icon: isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 40.0,
                            onPressed: () {
                              setState(() {
                                isPlaying
                                    ? _videoPlayerController?.pause()
                                    : _videoPlayerController?.play();
                              });
                              _startControlsTimer();
                            },
                          ),
                          const SizedBox(width: 12.0),
                          if (isVod)
                            _controlButton(
                              node: _forwardNode,
                              icon: Icons.forward_10_rounded,
                              size: 24.0,
                              onPressed: () =>
                                  _seekRelative(const Duration(seconds: 10)),
                            ),
                          const SizedBox(width: 20.0),
                          _controlButton(
                            node: _audioNode,
                            icon: Icons.translate_rounded,
                            size: 24.0,
                            onPressed: _showAudioMenu,
                          ),
                          const SizedBox(width: 6.0),
                          _controlButton(
                            node: _codecNode,
                            icon: Icons.settings_input_component_rounded,
                            size: 24.0,
                            onPressed: _switchCodec,
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isVod)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: VideoProgressIndicator(
                          _videoPlayerController!,
                          allowScrubbing: true,
                          colors: const VideoProgressColors(
                            playedColor: Colors.red,
                            bufferedColor: Colors.white24,
                            backgroundColor: Colors.white10,
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40.0,
                        vertical: 12.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11.0,
                            ),
                          ),
                          if (isVod)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 5.0,
                                    vertical: 1.5,
                                  ),
                                  margin: const EdgeInsets.only(right: 8.0),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.8,
                                    ),
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8.0,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDuration(duration),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11.0,
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5.0,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4.0),
                              ),
                              child: Text(
                                statusLabel,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
