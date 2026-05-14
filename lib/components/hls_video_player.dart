import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:tvplus/player_status.dart';
import 'dart:async';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:tvplus/components/web_video_player.dart';
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

  List<dynamic> _audioTracks = [];

  int _currentAudioIndex = 0;

  final FocusNode _playPauseNode = FocusNode();

  final FocusNode _audioTrackNode = FocusNode();

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

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 4), () {
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

  Future<void> _initializePlayer() async {
    if (_currentStatus == PlayerStatus.webFallback) {
      return;
    }
    setState(() {
      _isInitialized = false;
      _errorMessage = null;
      _audioTracks = [];
      _currentAudioIndex = 0;
    });
    try {
      _videoPlayerController?.dispose();
      await WakelockPlus.enable();
      final Map<String, String> headers = {
        'User-Agent':
            widget.userAgent ??
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': '*/*',
        'Connection': 'keep-alive',
      };
      if (widget.referer != null && widget.referer!.isNotEmpty) {
        headers['Referer'] = widget.referer;
      }
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.url),
        httpHeaders: headers,
        videoPlayerOptions: VideoPlayerOptions(allowBackgroundPlayback: true),
      );
      await _videoPlayerController?.initialize();
      _videoPlayerController?.addListener(_listener);
      _videoPlayerController?.play();
      try {} catch (e) {
        debugPrint('Audio track detection not supported: ${e}');
      }
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _showControls = true;
        });
        _startControlsTimer();
      }
    } catch (e) {
      _handleError(e.toString());
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
  }

  void _switchAudioTrack() {
    if (_videoPlayerController == null || _audioTracks.length <= 1) {
      return;
    }
    _currentAudioIndex = (_currentAudioIndex + 1) % _audioTracks.length;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Pista de audio ${_currentAudioIndex + 1} activada'),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.red.withOpacity(0.8),
      ),
    );
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
    _audioTrackNode.dispose();
    super.dispose();
  }

  Widget _controlButton({
    required FocusNode node,
    required IconData icon,
    required void Function() onPressed,
    double size = 32,
  }) {
    return Focus(
      focusNode: node,
      descendantsAreFocusable: false,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          onPressed();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        decoration: BoxDecoration(
          color: node.hasFocus
              ? Colors.white.withOpacity(0.3)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: node.hasFocus ? Colors.white : Colors.transparent,
            width: 3.0,
          ),
          boxShadow: [
            if (node.hasFocus)
              BoxShadow(
                color: Colors.white.withOpacity(0.2),
                blurRadius: 10.0,
                spreadRadius: 2.0,
              ),
          ],
        ),
        child: IconButton(
          icon: Icon(icon, color: Colors.white, size: size),
          onPressed: onPressed,
        ),
      ),
    );
  }

  Widget _buildCustomControls() {
    final bool isPlaying = _videoPlayerController?.value.isPlaying ?? false;
    return Positioned.fill(
      child: AnimatedOpacity(
        opacity: _showControls ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: IgnorePointer(
          ignoring: !_showControls,
          child: Container(
            color: Colors.black54,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Spacer(),
                FocusTraversalGroup(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _controlButton(
                        node: _playPauseNode,
                        icon: isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        size: 64.0,
                        onPressed: () {
                          setState(() {
                            isPlaying
                                ? _videoPlayerController?.pause()
                                : _videoPlayerController?.play();
                          });
                          _startControlsTimer();
                        },
                      ),
                      if (_audioTracks.length > 1) ...[
                        const SizedBox(width: 32.0),
                        _controlButton(
                          node: _audioTrackNode,
                          icon: Icons.audiotrack_rounded,
                          size: 48.0,
                          onPressed: _switchAudioTrack,
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(),
                const SizedBox(height: 30.0),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNativePlayer() {
    final bool hasError =
        _errorMessage != null ||
        (_videoPlayerController?.value.hasError ?? false);
    final String? logoUrl = widget.logoUrl;
    return FocusScope(
      child: Focus(
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (!_showControls &&
                (event.logicalKey == LogicalKeyboardKey.arrowUp ||
                    event.logicalKey == LogicalKeyboardKey.arrowDown ||
                    event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                    event.logicalKey == LogicalKeyboardKey.arrowRight ||
                    event.logicalKey == LogicalKeyboardKey.enter ||
                    event.logicalKey == LogicalKeyboardKey.select)) {
              setState(() {
                _showControls = true;
                _startControlsTimer();
              });
              _playPauseNode.requestFocus();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.backspace ||
                event.logicalKey == LogicalKeyboardKey.escape) {
              if (_showControls) {
                setState(() => _showControls = false);
                return KeyEventResult.handled;
              }
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
                  color: Colors.black.withOpacity(0.5),
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            if (_videoPlayerController != null && _isInitialized && !hasError)
              GestureDetector(
                onTap: _toggleControls,
                child: AspectRatio(
                  aspectRatio: 16 / 9,
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
      ),
    );
  }
}
