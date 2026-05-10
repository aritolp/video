import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/services.dart';
import 'package:tvplus/models/lista_de_canales.dart';

@NowaGenerated()
class ChannelCard extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const ChannelCard({
    super.key,
    required this.channel,
    required this.isCurrentlyPlaying,
    required this.onTap,
    this.autofocus = false,
  });

  final listaDeCanales channel;

  final bool isCurrentlyPlaying;

  final void Function() onTap;

  final bool autofocus;

  @override
  State<ChannelCard> createState() {
    return _ChannelCardState();
  }
}

@NowaGenerated()
class _ChannelCardState extends State<ChannelCard> {
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final String channelLogo =
        (widget.channel.logo != null && widget.channel.logo!.isNotEmpty)
        ? widget.channel.logo!
        : 'https://images.unsplash.com/photo-1594908900066-3f47337549d8?w=400';
    return Focus(
      autofocus: widget.autofocus,
      onFocusChange: (hasFocus) {
        setState(() {
          _isFocused = hasFocus;
        });
      },
      onKeyEvent: (node, event) {
        if (_isFocused &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          widget.onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isFocused ? 1.08 : 1.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                if (_isFocused)
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.6),
                    blurRadius: 20.0,
                    spreadRadius: 4.0,
                  )
                else if (widget.isCurrentlyPlaying)
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.3),
                    blurRadius: 12.0,
                    spreadRadius: 2.0,
                  ),
              ],
              border: Border.all(
                color: _isFocused
                    ? Colors.white
                    : (widget.isCurrentlyPlaying
                          ? Colors.red
                          : Colors.white.withValues(alpha: 0.1)),
                width: _isFocused
                    ? 3.0
                    : (widget.isCurrentlyPlaying ? 2.0 : 1.0),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14.0),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      channelLogo,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white10,
                        child: const Icon(Icons.tv, color: Colors.white24),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            (widget.isCurrentlyPlaying || _isFocused)
                                ? Colors.red.withValues(alpha: 0.8)
                                : Colors.black.withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12.0,
                    left: 12.0,
                    right: 12.0,
                    child: Text(
                      widget.channel.nombre ?? 'Canal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: (widget.isCurrentlyPlaying || _isFocused)
                            ? FontWeight.bold
                            : FontWeight.w500,
                        letterSpacing: 0.3,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
