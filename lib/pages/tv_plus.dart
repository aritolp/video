import 'package:flutter/material.dart';
import 'package:tvplus/models/lista_de_canales.dart';
import 'package:tvplus/player_status.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:tvplus/integrations/supabase_service.dart';
import 'package:tvplus/globals/app_state.dart';
import 'package:tvplus/main.dart';
import 'package:flutter/services.dart';
import 'package:tvplus/components/category_chip.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:tvplus/components/hls_video_player.dart';
import 'package:tvplus/components/channel_card.dart';

@NowaGenerated()
class TvPlus extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const TvPlus({super.key});

  @override
  State<TvPlus> createState() {
    return _TvPlusState();
  }
}

@NowaGenerated()
class _TvPlusState extends State<TvPlus> with TickerProviderStateMixin {
  listaDeCanales? selectedChannel;

  Future<List<listaDeCanales>>? _channelsFuture;

  int? _selectedChannelId;

  String playerMessage = 'Iniciando...';

  PlayerStatus playerStatus = PlayerStatus.connecting;

  int _refreshCount = 0;

  late AnimationController _pulseController;

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getBadgeColor() {
    switch (playerStatus) {
      case PlayerStatus.connecting:
        return Colors.yellow;
      case PlayerStatus.retrying:
        return Colors.orange;
      case PlayerStatus.webFallback:
        return Colors.blue;
      case PlayerStatus.playing:
        return Colors.red;
      case PlayerStatus.error:
        return Colors.grey;
    }
  }

  void _refreshChannels() {
    setState(() {
      _channelsFuture = SupabaseService().getAllCanales();
      playerMessage = 'Recargando...';
      _refreshCount++;
    });
  }

  @override
  void initState() {
    super.initState();
    _channelsFuture = SupabaseService().getAllCanales();
    _loadPreferences();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  void _onChannelSelected(listaDeCanales channel) {
    AppState.of(context, listen: false).setSelectedChannel(channel);
    if (mounted) {
      setState(() {
        playerMessage = 'Cargando...';
        playerStatus = PlayerStatus.connecting;
      });
    }
    sharedPrefs.setInt('last_channel_id', channel.id ?? 0);
    SupabaseService().updateLastChannel(channel.id ?? 0);
  }

  void _handleSystemUI(bool isLandscape) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isLandscape) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    });
  }

  Widget _buildCategoryFilters(
    List<listaDeCanales> channels,
    AppState appState,
  ) {
    final categories = channels
        .map((c) => c.categoria ?? 'General')
        .toSet()
        .toList();
    categories.sort();
    return Container(
      height: 45.0,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 12.0),
        itemBuilder: (context, index) {
          final isAll = index == 0;
          final category = isAll ? null : categories[index - 1];
          final isSelected = appState.selectedCategory == category;
          return CategoryChip(
            label: isAll ? 'TODOS' : category!,
            isSelected: isSelected,
            onSelected: (selected) {
              appState.setSelectedCategory(selected ? category : null);
            },
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          '¿Quieres salir de tu cuenta?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'SÍ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client.auth.signOut();
      await sharedPrefs.remove('bypass_auth');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  Future<void> _loadPreferences() async {
    final lastId = sharedPrefs.getInt('last_channel_id');
    if (mounted) {
      final appState = AppState.of(context, listen: false);
      appState.loadFavorites();
      if (lastId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            appState.setSelectedChannelId(lastId);
          }
        });
      }
    }
  }

  void _toggleFavorite(int channelId) {
    AppState.of(context, listen: false).toggleFavorite(channelId);
  }

  Widget _buildAboutSection(AppState appState) {
    final info = appState.appInfo;
    if (info == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100.0,
            height: 100.0,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Icon(Icons.tv, size: 50.0, color: Colors.white),
          ),
          const SizedBox(height: 32.0),
          Text(
            info.nombreApp,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28.0,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            'Versión ${info.version}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 14.0,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 48.0),
          _buildInfoRow('Soporte', info.correo),
          const SizedBox(height: 16.0),
          _buildInfoRow('Sitio Web', info.sitioWeb),
          const Spacer(),
          Text(
            'Diseñado con minimalismo en mente',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.2),
              fontSize: 12.0,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 15.0,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final favoriteColor = Colors.red.withValues(alpha: 0.7);
    return OrientationBuilder(
      builder: (context, orientation) {
        final bool isLandscape = orientation == Orientation.landscape;
        _handleSystemUI(isLandscape);
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              return;
            }
            if (appState.isShowingAbout || appState.isShowingFavorites) {
              appState.setShowingAbout(false);
              appState.setShowingFavorites(false);
            } else if (isLandscape) {
              SystemChrome.setPreferredOrientations([
                DeviceOrientation.portraitUp,
              ]);
            } else {
              final bool? confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Salir',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    '¿Quieres salir de la aplicación?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('NO'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'SÍ',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                SystemNavigator.pop();
              }
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: SafeArea(
              top: !isLandscape,
              bottom: !isLandscape,
              left: !isLandscape,
              right: !isLandscape,
              child: DataBuilder<List<listaDeCanales>>(
                future: _channelsFuture,
                builder: (context, channels) {
                  if (channels == null || channels.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          CircularProgressIndicator(color: Colors.red),
                          SizedBox(height: 16.0),
                          Text(
                            'Cargando canales...',
                            style: TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    );
                  }
                  List<listaDeCanales> filteredChannels;
                  if (appState.isShowingFavorites) {
                    final favIds = appState.favoriteChannels ?? [];
                    filteredChannels = channels
                        .where((c) => favIds.contains(c.id))
                        .toList();
                  } else if (appState.selectedCategory != null) {
                    filteredChannels = channels
                        .where(
                          (c) =>
                              (c.categoria ?? 'General').toLowerCase() ==
                              appState.selectedCategory?.toLowerCase(),
                        )
                        .toList();
                  } else {
                    filteredChannels = channels;
                  }
                  final currentChannel = channels.firstWhere(
                    (c) => c.id == appState.selectedChannelId,
                    orElse: () => channels[0],
                  );
                  final String? rawUrl = currentChannel.url_stream;
                  final String streamUrl =
                      (rawUrl != null && rawUrl!.isNotEmpty)
                      ? rawUrl!
                      : 'https://livetrx01.vodgc.net/eltrecetv/index.m3u8';
                  final String? logoUrl =
                      (currentChannel.logo != null &&
                          currentChannel.logo!.isNotEmpty)
                      ? currentChannel.logo
                      : null;
                  final playerWidget = AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: isLandscape
                            ? BorderRadius.zero
                            : BorderRadius.circular(16.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: HlsVideoPlayer(
                        key: ValueKey('${streamUrl}_${_refreshCount}'),
                        url: streamUrl,
                        logoUrl: logoUrl,
                        userAgent: currentChannel.userAgent,
                        referer: currentChannel.referer,
                        onStatusChanged: (status, message) {
                          if (mounted) {
                            setState(() {
                              playerStatus = status;
                              playerMessage = message;
                            });
                          }
                        },
                      ),
                    ),
                  );
                  if (isLandscape) {
                    return Container(
                      color: Colors.black,
                      width: double.infinity,
                      height: double.infinity,
                      child: Center(child: playerWidget),
                    );
                  }
                  final bool isFavorite = (appState.favoriteChannels ?? [])
                      .contains(currentChannel.id);
                  return LayoutBuilder(
                    builder: (context, constraints) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: playerWidget,
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            20.0,
                            20.0,
                            20.0,
                            0.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      currentChannel.nombre ??
                                          'Canal sin nombre',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4.0),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            'Señal: ${currentChannel.categoria ?? 'En vivo'}',
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11.0,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12.0),
                                        FadeTransition(
                                          opacity:
                                              playerStatus ==
                                                  PlayerStatus.connecting
                                              ? _pulseController
                                              : const AlwaysStoppedAnimation(1),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0,
                                              vertical: 3.0,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getBadgeColor()
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4.0),
                                              border: Border.all(
                                                color: _getBadgeColor()
                                                    .withValues(alpha: 0.5),
                                                width: 1.0,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6.0,
                                                  height: 6.0,
                                                  decoration: BoxDecoration(
                                                    color: _getBadgeColor(),
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                const SizedBox(width: 6.0),
                                                Flexible(
                                                  child: Text(
                                                    playerMessage.toUpperCase(),
                                                    style: TextStyle(
                                                      color: _getBadgeColor(),
                                                      fontSize: 9.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      letterSpacing: 0.5,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _toggleFavorite(currentChannel.id ?? 0),
                                    icon: Icon(
                                      isFavorite
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: isFavorite
                                          ? favoriteColor
                                          : Colors.white38,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _refreshChannels,
                                    icon: const Icon(
                                      Icons.refresh,
                                      color: Colors.white54,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: _logout,
                                    icon: const Icon(
                                      Icons.logout,
                                      color: Colors.white54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24.0),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () => appState.setShowingAbout(false),
                                child: Text(
                                  'CANALES',
                                  style: TextStyle(
                                    color:
                                        (!appState.isShowingFavorites &&
                                            !appState.isShowingAbout)
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => appState.setShowingFavorites(true),
                                child: Text(
                                  'FAVORITOS',
                                  style: TextStyle(
                                    color: appState.isShowingFavorites
                                        ? favoriteColor
                                        : Colors.white38,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => appState.setShowingAbout(true),
                                child: Text(
                                  'acerca de..',
                                  style: TextStyle(
                                    color: appState.isShowingAbout
                                        ? Colors.white
                                        : Colors.white38,
                                    fontSize: 14.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12.0),
                        if (appState.isShowingAbout)
                          Expanded(child: _buildAboutSection(appState))
                        else ...[
                          _buildCategoryFilters(channels, appState),
                          const SizedBox(height: 8.0),
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20.0,
                                vertical: 10.0,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 1.5,
                                    crossAxisSpacing: 16.0,
                                    mainAxisSpacing: 16.0,
                                  ),
                              itemCount: filteredChannels.length,
                              itemBuilder: (context, index) {
                                final channel = filteredChannels[index];
                                final isSelected =
                                    currentChannel.id == channel.id;
                                return ChannelCard(
                                  channel: channel,
                                  isCurrentlyPlaying: isSelected,
                                  onTap: () => _onChannelSelected(channel),
                                  autofocus: index == 0,
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
