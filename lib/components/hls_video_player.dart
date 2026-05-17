import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:tvplus/player_status.dart';
import 'dart:async';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:flutter/services.dart';
import 'package:tvplus/components/web_video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

@NowaGenerated()
class HlsVideoPlayer extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const HlsVideoPlayer({
    required this.url,
    this.userAgent,
    this.referer,
    this.onStatusChanged,
    this.logoUrl,
    this.onToggleFullScreen,
    super.key,
  });

  final String url;

  final String? userAgent;

  final String? referer;

  final void Function(PlayerStatus status, String message)? onStatusChanged;

  final String? logoUrl;

  final void Function()? onToggleFullScreen;

  @override
  State<HlsVideoPlayer> createState() {
    return _HlsVideoPlayerState();
  }
}

@NowaGenerated()
class _HlsVideoPlayerState extends State<HlsVideoPlayer> {
  Player? _player;

  VideoController? _videoController;

  bool _isInitialized = false;

  String? _errorMessage;

  int _retryCount = 0;

  PlayerStatus _currentStatus = PlayerStatus.connecting;

  Timer? _retryTimer;

  Timer? _fallbackTimer;

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

  bool _isPlaying = false;

  Duration _position = Duration.zero;

  Duration _duration = Duration.zero;

  bool _isBuffering = false;

  final FocusNode _subtitleNode = FocusNode();

  final FocusNode _switchPlayerNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _initializePlayer();
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

  void _startFallbackTimer() {
    _fallbackTimer?.cancel();
    _fallbackTimer = Timer(const Duration(seconds: 7), () {
      if (mounted &&
          _currentStatus != PlayerStatus.playing &&
          _currentStatus != PlayerStatus.webFallback) {
        _updateStatus(PlayerStatus.webFallback, 'Modo Alternativo (Timeout)');
      }
    });
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
      _player?.dispose();
      _player = null;
      _videoController = null;
      _fallbackTimer?.cancel();
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
    final player = _player;
    if (player == null || !_isInitialized) {
      return;
    }
    final newPosition = _position + offset;
    if (newPosition < Duration.zero) {
      await player.seek(Duration.zero);
    } else if (newPosition > _duration) {
      await player.seek(_duration);
    } else {
      await player.seek(newPosition);
    }
    _startControlsTimer();
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
    _volume = (_volume * 100 + delta * 100).clamp(0.0, 100.0) / 100.0;
    if (_player != null) {
      _player?.setVolume(_volume * 100);
    }
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

  Future<void> _showAudioMenu() async {
    if (_player == null) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Optimizando pistas de audio y reconectando...'),
        duration: Duration(seconds: 2),
        backgroundColor: Colors.blue,
      ),
    );
    _initializePlayer();
  }

  Widget _buildNativePlayer() {
    final bool hasError = _errorMessage != null;
    final String? logoUrl = widget.logoUrl;
    final controller = _videoController;
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.backspace ||
              event.logicalKey == LogicalKeyboardKey.escape ||
              event.logicalKey == LogicalKeyboardKey.goBack) {
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
          if (controller != null && _isInitialized && !hasError)
            Center(
              child: Video(controller: controller, controls: NoVideoControls),
            ),
          _buildCustomControls(),
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
  void didUpdateWidget(HlsVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _retryCount = 0;
      _currentStatus = PlayerStatus.connecting;
      _initializePlayer();
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
      child: AnimatedScale(
        scale: node.hasFocus ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(2.0),
          decoration: BoxDecoration(
            color: node.hasFocus
                ? Colors.red.withValues(alpha: 0.4)
                : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: node.hasFocus ? Colors.white : Colors.transparent,
              width: 2.0,
            ),
            boxShadow: [
              if (node.hasFocus)
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.3),
                  blurRadius: 12.0,
                  spreadRadius: 2.0,
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
      ),
    );
  }

  Future<void> _showSubtitleMenu() async {
    final player = _player;
    if (player == null) {
      return;
    }
    final tracks = player.state.tracks.subtitle;
    if (tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay subtítulos disponibles para este canal'),
        ),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black87,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Subtítulos',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10.0),
            ...tracks.map((track) {
              final isSelected = player.state.track.subtitle == track;
              return ListTile(
                leading: Icon(
                  Icons.subtitles,
                  color: isSelected ? Colors.red : Colors.white70,
                ),
                title: Text(
                  track.title ??
                      track.language ??
                      'Pista ${tracks.indexOf(track)}',
                  style: TextStyle(
                    color: isSelected ? Colors.red : Colors.white,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.red)
                    : null,
                onTap: () {
                  player.setSubtitleTrack(track);
                  Navigator.pop(context);
                },
              );
            }).toList(),
            ListTile(
              leading: const Icon(Icons.subtitles_off, color: Colors.white70),
              title: const Text(
                'Desactivar Subtítulos',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                player.setSubtitleTrack(SubtitleTrack.no());
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _switchPlayerNode.dispose();
    _subtitleNode.dispose();
    _retryTimer?.cancel();
    _fallbackTimer?.cancel();
    _controlsTimer?.cancel();
    _player?.dispose();
    WakelockPlus.disable();
    _playPauseNode.dispose();
    _codecNode.dispose();
    _rewindNode.dispose();
    _forwardNode.dispose();
    _audioNode.dispose();
    super.dispose();
  }

  Widget _buildCustomControls() {
    final bool isPlaying = _isPlaying;
    final Duration position = _position;
    final Duration duration = _duration;
    final bool isVod = duration > Duration.zero && duration.inSeconds > 0;
    final player = _player;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _controlButton(
                                node: _switchPlayerNode,
                                icon: Icons.swap_calls_rounded,
                                onPressed: () {
                                  _updateStatus(
                                    PlayerStatus.webFallback,
                                    'Cambiando a Modo Web...',
                                  );
                                },
                              ),
                              const SizedBox(width: 8.0),
                              _controlButton(
                                node: FocusNode(),
                                icon: Icons.fullscreen_rounded,
                                onPressed: () {
                                  widget.onToggleFullScreen?.call();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                              if (player != null) {
                                isPlaying ? player.pause() : player.play();
                              }
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
                            node: _subtitleNode,
                            icon: Icons.closed_caption_rounded,
                            size: 24.0,
                            onPressed: _showSubtitleMenu,
                          ),
                          const SizedBox(width: 12.0),
                          _controlButton(
                            node: _audioNode,
                            icon: Icons.translate_rounded,
                            size: 24.0,
                            onPressed: _showAudioMenu,
                          ),
                          const SizedBox(width: 12.0),
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
                        child: SliderTheme(
                          data: const SliderThemeData(
                            trackHeight: 2.0,
                            thumbShape: RoundSliderThumbShape(
                              enabledThumbRadius: 6.0,
                            ),
                            activeTrackColor: Colors.red,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.red,
                          ),
                          child: Slider(
                            value: position.inMilliseconds.toDouble().clamp(
                              0.0,
                              duration.inMilliseconds.toDouble(),
                            ),
                            max: duration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              player?.seek(
                                Duration(milliseconds: value.toInt()),
                              );
                            },
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6.0,
                                  vertical: 2.0,
                                ),
                                decoration: BoxDecoration(
                                  color: isVod
                                      ? Colors.blueAccent.withValues(alpha: 0.8)
                                      : Colors.red,
                                  borderRadius: BorderRadius.circular(4.0),
                                ),
                                child: Text(
                                  isVod ? 'VIDEO' : 'EN VIVO',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Text(
                                isVod
                                    ? _formatDuration(duration)
                                    : _formatDuration(position),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          if (isVod)
                            Text(
                              _formatDuration(duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11.0,
                              ),
                            )
                          else
                            const SizedBox(width: 40.0),
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

  void _handleError(String error) {
    if (_currentStatus == PlayerStatus.webFallback || !mounted) {
      return;
    }
    debugPrint('Player Error: ${error}');
    if (error.contains('Already opened') ||
        error.contains('Buffering') ||
        error.contains('Stop')) {
      return;
    }
    if (_retryTimer?.isActive ?? false) {
      return;
    }
    if (_retryCount < 3) {
      _retryCount++;
      _updateStatus(
        PlayerStatus.retrying,
        'Reconectando (${_retryCount}/3)...',
      );
      _retryTimer?.cancel();
      _retryTimer = Timer(Duration(seconds: 4 * _retryCount), () {
        if (mounted) {
          _initializePlayer();
        }
      });
    } else {
      _updateStatus(
        PlayerStatus.webFallback,
        'Cambiando a Modo Alternativo...',
      );
    }
  }

  Future<void> _initializePlayer() async {
    if (_currentStatus == PlayerStatus.webFallback) {
      return;
    }
    _retryTimer?.cancel();
    _startFallbackTimer();
    if (_player == null) {
      setState(() {
        _isInitialized = false;
        _errorMessage = null;
      });
    }
    try {
      final Duration lastPosition = _position;
      await _player?.dispose();
      await WakelockPlus.enable();
      final PlayerConfiguration configuration = const PlayerConfiguration();
      final player = Player(configuration: configuration);
      _player = player;
      _videoController = VideoController(player);
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
      player.stream.playing.listen((playing) {
        if (mounted) {
          setState(() {
            _isPlaying = playing;
          });
          if (playing && _currentStatus != PlayerStatus.playing) {
            _updateStatus(PlayerStatus.playing, 'En vivo');
            _retryCount = 0;
            _fallbackTimer?.cancel();
          }
        }
      });
      player.stream.position.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });
      player.stream.duration.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration;
          });
        }
      });
      player.stream.buffering.listen((buffering) {
        if (mounted) {
          final wasBuffering = _isBuffering;
          setState(() {
            _isBuffering = buffering;
          });
          if (wasBuffering && !buffering && !_isPlaying) {
            final isVod = _duration > Duration.zero && _duration.inSeconds > 0;
            if (isVod) {
              _player?.play();
            } else {
              _player?.play();
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _player != null && !_isPlaying) {
                  _player?.seek(const Duration(days: 1)).then((_) {
                    _player?.play();
                  });
                }
              });
            }
          }
        }
      });
      player.stream.error.listen((error) {
        if (mounted && error.isNotEmpty) {
          if (!error.contains('Already opened') &&
              !error.contains('Buffering') &&
              !error.contains('Stop')) {
            _handleError(error);
          }
        }
      });
      await player.open(Media(widget.url, httpHeaders: headers), play: false);
      await player.setVolume(_volume * 100);
      if (lastPosition > Duration.zero) {
        await player.seek(lastPosition);
      }
      await player.play();
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
      if (!e.toString().contains('already') &&
          !e.toString().contains('playing')) {
        _handleError(e.toString());
      }
    }
  }
}
