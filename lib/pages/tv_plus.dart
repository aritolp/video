import 'package:flutter/material.dart';
import 'package:tvplus/models/lista_de_canales.dart';
import 'package:tvplus/player_status.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:tvplus/integrations/supabase_service.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tvplus/main.dart';
import 'package:go_router/go_router.dart';
import 'package:tvplus/globals/app_state.dart';
import 'package:tvplus/components/category_chip.dart';
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

  bool _isFullScreen = false;

  final FocusNode _playerNode = FocusNode();

  final FocusNode _channelsTabNode = FocusNode();

  final FocusNode _favoritesTabNode = FocusNode();

  final FocusNode _aboutTabNode = FocusNode();

  final FocusNode _favBtnNode = FocusNode();

  final FocusNode _refreshBtnNode = FocusNode();

  final FocusNode _logoutBtnNode = FocusNode();

  String _searchQuery = '';

  final FocusNode _searchNode = FocusNode();

  final TextEditingController _searchController = TextEditingController();

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

  void _handleSystemUI(bool isLandscape) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isLandscape || _isFullScreen) {
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

  Future<void> _toggleFullScreen() async {
    if (!_isFullScreen) {
      final bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Pantalla completa',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            '¿Deseas ver el canal en pantalla completa?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'PANTALLA COMPLETA',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      );
      if (confirm == true) {
        setState(() => _isFullScreen = true);
      }
    } else {
      setState(() => _isFullScreen = false);
    }
  }

  Widget _buildTabButton(
    String label,
    bool isSelected,
    FocusNode node,
    void Function() onTap,
  ) {
    final bool hasFocus = node.hasFocus;
    return Focus(
      focusNode: node,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.enter ||
                event.logicalKey == LogicalKeyboardKey.select)) {
          onTap();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: hasFocus
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10.0),
            border: Border.all(
              color: hasFocus ? Colors.red : Colors.transparent,
              width: 2.0,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.red
                  : (hasFocus ? Colors.white : Colors.white38),
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelInfo(
    listaDeCanales currentChannel,
    Color favoriteColor,
    bool isFavorite,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 20.0, 0.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentChannel.nombre ?? 'Canal sin nombre',
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
                      opacity: playerStatus == PlayerStatus.connecting
                          ? _pulseController
                          : const AlwaysStoppedAnimation(1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 3.0,
                        ),
                        decoration: BoxDecoration(
                          color: _getBadgeColor().withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: _getBadgeColor().withValues(alpha: 0.5),
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
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
              _buildFocusIconButton(
                node: _favBtnNode,
                icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                color: isFavorite
                    ? favoriteColor
                    : (_favBtnNode.hasFocus ? Colors.white : Colors.white38),
                onPressed: () => _toggleFavorite(currentChannel.id ?? 0),
              ),
              _buildFocusIconButton(
                node: _refreshBtnNode,
                icon: Icons.refresh,
                color: _refreshBtnNode.hasFocus ? Colors.white : Colors.white54,
                onPressed: _refreshChannels,
              ),
              _buildFocusIconButton(
                node: _logoutBtnNode,
                icon: Icons.logout,
                color: _logoutBtnNode.hasFocus ? Colors.white : Colors.white54,
                onPressed: _logout,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFocusIconButton({
    required FocusNode node,
    required IconData icon,
    required Color color,
    required void Function() onPressed,
  }) {
    return Focus(
      focusNode: node,
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
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        decoration: BoxDecoration(
          color: node.hasFocus
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(
            color: node.hasFocus ? Colors.white : Colors.transparent,
            width: 2.0,
          ),
        ),
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(
    List<listaDeCanales> channels,
    AppState appState,
  ) {
    final allChannels = [...channels, ...appState.externalChannels];
    final categories = allChannels
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

  Widget _buildAboutSection(AppState appState) {
    final info = appState.appInfo;
    if (info == null) {
      return const Center(child: CircularProgressIndicator(color: Colors.red));
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80.0,
              height: 80.0,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.tv, size: 40.0, color: Colors.white),
            ),
            const SizedBox(height: 24.0),
            Text(
              info.nombreApp,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 32.0),
            _buildM3UImportSection(appState),
            const SizedBox(height: 32.0),
            _buildInfoRow('Soporte', info.correo),
            const SizedBox(height: 12.0),
            _buildInfoRow('Sitio Web', info.sitioWeb),
            const SizedBox(height: 20.0),
            Text(
              'Versión ${info.version}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3),
                fontSize: 12.0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildM3UImportSection(AppState appState) {
    final hasExternal = appState.externalChannels.isNotEmpty;
    final FocusNode _m3uBtnNode = FocusNode();
    final FocusNode _m3uDelNode = FocusNode();
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.link, color: Colors.red, size: 20.0),
              const SizedBox(width: 12.0),
              const Expanded(
                child: Text(
                  'Lista M3U Externa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (hasExternal)
                Focus(
                  focusNode: _m3uDelNode,
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent &&
                        (event.logicalKey == LogicalKeyboardKey.enter ||
                            event.logicalKey == LogicalKeyboardKey.select)) {
                      appState.clearExternalM3U();
                      return KeyEventResult.handled;
                    }
                    return KeyEventResult.ignored;
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: _m3uDelNode.hasFocus
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => appState.clearExternalM3U(),
                      icon: Icon(
                        Icons.delete_outline,
                        color: _m3uDelNode.hasFocus
                            ? Colors.white
                            : Colors.white54,
                        size: 20.0,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8.0),
          Text(
            hasExternal
                ? '${appState.externalChannels.length} canales cargados'
                : 'Carga una lista M3U o Xtream Codes',
            style: const TextStyle(color: Colors.white54, fontSize: 12.0),
          ),
          const SizedBox(height: 16.0),
          Focus(
            focusNode: _m3uBtnNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.select)) {
                _showM3UDialog(appState);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: ElevatedButton(
              onPressed: () => _showM3UDialog(appState),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: _m3uBtnNode.hasFocus
                      ? Colors.white
                      : Colors.transparent,
                  width: 2.0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text(hasExternal ? 'Actualizar Lista' : 'Configurar M3U'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleM3ULoad(AppState appState, String url) async {
    try {
      if (url.isNotEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Cargando canales M3U...')),
        );
        await appState.loadExternalM3U(url);
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(
            content: Text(
              '¡${appState.externalChannels.length} canales cargados con éxito!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Error: ${e}'), backgroundColor: Colors.red),
      );
    }
  }

  void _onChannelSelected(listaDeCanales channel) {
    AppState.of(context, listen: false).setSelectedChannel(channel);
    if (mounted) {
      setState(() {
        playerMessage = 'Cargando...';
        playerStatus = PlayerStatus.connecting;
      });
    }
    if (channel.id != null && channel.id! > 0) {
      sharedPrefs.setInt('last_channel_id', channel.id ?? 0);
      SupabaseService().updateLastChannel(channel.id ?? 0);
    } else if (channel.url_stream != null) {
      sharedPrefs.setInt('last_channel_id', channel.id ?? -1);
    }
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
    _playerNode.addListener(() => setState(() {}));
    _channelsTabNode.addListener(() => setState(() {}));
    _favoritesTabNode.addListener(() => setState(() {}));
    _aboutTabNode.addListener(() => setState(() {}));
    _favBtnNode.addListener(() => setState(() {}));
    _refreshBtnNode.addListener(() => setState(() {}));
    _logoutBtnNode.addListener(() => setState(() {}));
    _searchNode.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppState.of(context, listen: false).loadSavedExternalM3U();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _playerNode.dispose();
    _channelsTabNode.dispose();
    _favoritesTabNode.dispose();
    _aboutTabNode.dispose();
    _favBtnNode.dispose();
    _refreshBtnNode.dispose();
    _logoutBtnNode.dispose();
    _searchNode.dispose();
    _searchController.dispose();
    super.dispose();
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
            if (_isFullScreen) {
              setState(() => _isFullScreen = false);
              return;
            }
            if (appState.isShowingAbout || appState.isShowingFavorites) {
              appState.setShowingAbout(false);
              appState.setShowingFavorites(false);
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
                  final allChannelsAvailable = [
                    ...channels,
                    ...appState.externalChannels,
                  ];
                  final currentChannel =
                      appState.selectedChannel ??
                      (allChannelsAvailable.firstWhere(
                        (c) => c.id == appState.selectedChannelId,
                        orElse: () => allChannelsAvailable[0],
                      ));
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
                  final playerWidget = Focus(
                    focusNode: _playerNode,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.select)) {
                        _toggleFullScreen();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: GestureDetector(
                      onTap: _toggleFullScreen,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: (_playerNode.hasFocus && !_isFullScreen)
                            ? const EdgeInsets.all(4.0)
                            : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: (_playerNode.hasFocus && !_isFullScreen)
                              ? Colors.red
                              : Colors.transparent,
                          borderRadius: (_isFullScreen || isLandscape)
                              ? BorderRadius.zero
                              : BorderRadius.circular(20.0),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: (_isFullScreen || isLandscape)
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
                        ),
                      ),
                    ),
                  );
                  if (_isFullScreen) {
                    return Container(
                      color: Colors.black,
                      width: double.infinity,
                      height: double.infinity,
                      child: Center(child: playerWidget),
                    );
                  }
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      if (constraints.maxWidth > 700) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 3,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: playerWidget,
                                    ),
                                    _buildChannelInfo(
                                      currentChannel,
                                      favoriteColor,
                                      (appState.favoriteChannels ?? [])
                                          .contains(currentChannel.id),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: _buildListSection(
                                appState,
                                channels,
                                [],
                                currentChannel,
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: playerWidget,
                            ),
                            _buildChannelInfo(
                              currentChannel,
                              favoriteColor,
                              (appState.favoriteChannels ?? []).contains(
                                currentChannel.id,
                              ),
                            ),
                            const SizedBox(height: 24.0),
                            Expanded(
                              child: _buildListSection(
                                appState,
                                channels,
                                [],
                                currentChannel,
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildListSection(
    AppState appState,
    List<listaDeCanales> channels,
    List<listaDeCanales> filteredChannels,
    listaDeCanales currentChannel,
  ) {
    final allChannelsForGrid = [...channels, ...appState.externalChannels];
    List<listaDeCanales> finalFiltered;
    if (appState.isShowingFavorites) {
      final favIds = appState.favoriteChannels ?? [];
      finalFiltered = allChannelsForGrid
          .where((c) => favIds.contains(c.id))
          .toList();
    } else if (appState.selectedCategory != null) {
      finalFiltered = allChannelsForGrid
          .where(
            (c) =>
                (c.categoria ?? 'General').toLowerCase() ==
                appState.selectedCategory?.toLowerCase(),
          )
          .toList();
    } else {
      finalFiltered = allChannelsForGrid;
    }
    if (_searchQuery.isNotEmpty) {
      finalFiltered = finalFiltered
          .where(
            (c) => (c.nombre ?? '').toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }
    final activeChannel = appState.selectedChannel ?? currentChannel;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTabButton(
                'CANALES',
                (!appState.isShowingFavorites && !appState.isShowingAbout),
                _channelsTabNode,
                () {
                  appState.setShowingAbout(false);
                  appState.setShowingFavorites(false);
                },
              ),
              _buildTabButton(
                'FAVORITOS',
                appState.isShowingFavorites,
                _favoritesTabNode,
                () {
                  appState.setShowingAbout(false);
                  appState.setShowingFavorites(true);
                },
              ),
              _buildTabButton(
                'ACERCA DE..',
                appState.isShowingAbout,
                _aboutTabNode,
                () {
                  appState.setShowingAbout(true);
                  appState.setShowingFavorites(false);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12.0),
        if (appState.isShowingAbout)
          Expanded(child: _buildAboutSection(appState))
        else ...[
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 8.0,
            ),
            child: Focus(
              focusNode: _searchNode,
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    FocusScope.of(context).nextFocus();
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    _channelsTabNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                height: 40.0,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: _searchNode.hasFocus ? Colors.red : Colors.white10,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 14.0),
                  decoration: InputDecoration(
                    hintText: 'Buscar contenido...',
                    hintStyle: const TextStyle(
                      color: Colors.white24,
                      fontSize: 13.0,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: _searchNode.hasFocus ? Colors.red : Colors.white38,
                      size: 20.0,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10.0),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
            ),
          ),
          _buildCategoryFilters(channels, appState),
          const SizedBox(height: 8.0),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10.0,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16.0,
                mainAxisSpacing: 16.0,
              ),
              itemCount: finalFiltered.length,
              itemBuilder: (context, index) {
                final channel = finalFiltered[index];
                final isSelected = activeChannel.id == channel.id;
                return ChannelCard(
                  channel: channel,
                  isCurrentlyPlaying: isSelected,
                  onTap: () => _onChannelSelected(channel),
                  autofocus: index == 0 && _searchQuery.isEmpty,
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  void _showM3UDialog(AppState appState) {
    final controller = TextEditingController(
      text: sharedPrefs.getString('external_m3u_url') ?? '',
    );
    final FocusNode _urlNode = FocusNode();
    final FocusNode _cancelNode = FocusNode();
    final FocusNode _loadNode = FocusNode();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Configurar M3U',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pega tu URL de M3U o Xtream Codes:',
                style: TextStyle(color: Colors.white70, fontSize: 13.0),
              ),
              const SizedBox(height: 16.0),
              Focus(
                focusNode: _urlNode,
                onKeyEvent: (node, event) {
                  if (event is KeyDownEvent &&
                      (event.logicalKey == LogicalKeyboardKey.enter ||
                          event.logicalKey == LogicalKeyboardKey.select)) {
                    _loadNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _urlNode.hasFocus
                          ? Colors.red
                          : Colors.transparent,
                      width: 2.0,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: TextField(
                    controller: controller,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'http://...',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.05),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          StatefulBuilder(
            builder: (context, setState) {
              _cancelNode.addListener(() => setState(() {}));
              _loadNode.addListener(() => setState(() {}));
              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Focus(
                    focusNode: _cancelNode,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.select)) {
                        Navigator.pop(context);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'CANCELAR',
                        style: TextStyle(
                          color: _cancelNode.hasFocus
                              ? Colors.white
                              : Colors.white54,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Focus(
                    focusNode: _loadNode,
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          (event.logicalKey == LogicalKeyboardKey.enter ||
                              event.logicalKey == LogicalKeyboardKey.select)) {
                        _handleM3ULoad(appState, controller.text.trim());
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: ElevatedButton(
                      onPressed: () =>
                          _handleM3ULoad(appState, controller.text.trim()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        side: BorderSide(
                          color: _loadNode.hasFocus
                              ? Colors.white
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                      child: const Text('CARGAR'),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
