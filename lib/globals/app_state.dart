import 'package:flutter/material.dart';
import 'package:tvplus/globals/themes.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:tvplus/models/lista_de_canales.dart';
import 'package:tvplus/models/app_info.dart';
import 'package:tvplus/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tvplus/integrations/supabase_service.dart';
import 'dart:async';
import 'package:provider/provider.dart';

@NowaGenerated()
class AppState extends ChangeNotifier {
  AppState();

  factory AppState.of(BuildContext context, {bool listen = true}) {
    return Provider.of<AppState>(context, listen: listen);
  }

  ThemeData _theme = lightTheme;

  ThemeData get theme {
    return _theme;
  }

  int? _selectedChannelId;

  int? get selectedChannelId {
    return _selectedChannelId;
  }

  listaDeCanales? _selectedChannel;

  listaDeCanales? get selectedChannel {
    return _selectedChannel;
  }

  String? _selectedCategory;

  String? get selectedCategory {
    return _selectedCategory;
  }

  List<int>? _favoriteChannels;

  List<int>? get favoriteChannels {
    return _favoriteChannels;
  }

  bool _isShowingFavorites = false;

  bool get isShowingFavorites {
    return _isShowingFavorites;
  }

  bool _isShowingAbout = false;

  bool get isShowingAbout {
    return _isShowingAbout;
  }

  AppInfo? _appInfo;

  AppInfo? get appInfo {
    return _appInfo;
  }

  List<listaDeCanales> _externalChannels = [];

  List<listaDeCanales> get externalChannels {
    return _externalChannels;
  }

  double _m3uProgress = 0.0;

  double get m3uProgress {
    return _m3uProgress;
  }

  void changeTheme(ThemeData theme) {
    _theme = theme;
    notifyListeners();
  }

  void setSelectedChannelId(int? id) {
    _selectedChannelId = id;
    notifyListeners();
  }

  void setSelectedChannel(listaDeCanales? channel) {
    _selectedChannel = channel;
    if (channel != null) {
      _selectedChannelId = channel.id;
    }
    notifyListeners();
  }

  Future<void> setFavoriteChannels(List<int> favorites) async {
    _favoriteChannels = favorites;
    sharedPrefs.setStringList(
      'favorite_channels',
      favorites.map((e) => e.toString()).toList(),
    );
    notifyListeners();
  }

  Future<void> toggleFavorite(int channelId) async {
    final user = Supabase.instance.client.auth.currentUser;
    List<int> currentFavorites = List.from(_favoriteChannels ?? []);
    if (currentFavorites.contains(channelId)) {
      currentFavorites.remove(channelId);
      if (user != null) {
        await SupabaseService().removeFavorite(channelId);
      }
    } else {
      currentFavorites.add(channelId);
      if (user != null) {
        await SupabaseService().addFavorite(channelId);
      }
    }
    await setFavoriteChannels(currentFavorites);
  }

  Future<void> loadFavorites() async {
    final List<String>? localFavs = sharedPrefs.getStringList(
      'favorite_channels',
    );
    if (localFavs != null) {
      _favoriteChannels = localFavs.map((e) => int.parse(e)).toList();
      notifyListeners();
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final cloudFavs = await SupabaseService().getFavorites();
      if (cloudFavs.isNotEmpty || _favoriteChannels == null) {
        _favoriteChannels = cloudFavs;
        sharedPrefs.setStringList(
          'favorite_channels',
          _favoriteChannels!.map((e) => e.toString()).toList(),
        );
        notifyListeners();
      }
    }
  }

  void setShowingAbout(bool value) {
    _isShowingAbout = value;
    if (value) {
      _isShowingFavorites = false;
      _selectedCategory = null;
      _fetchAppInfo();
    }
    notifyListeners();
  }

  void setShowingFavorites(bool value) {
    _isShowingFavorites = value;
    if (value) {
      _selectedCategory = null;
      _isShowingAbout = false;
    }
    notifyListeners();
  }

  void setSelectedCategory(String? category) {
    _selectedCategory = category;
    if (category != null) {
      _isShowingFavorites = false;
      _isShowingAbout = false;
    }
    notifyListeners();
  }

  Future<void> _fetchAppInfo() async {
    if (_appInfo == null) {
      _appInfo = await SupabaseService().getAppInfo();
      notifyListeners();
    }
  }

  Future<void> loadExternalM3U(String url) async {
    Timer? simulationTimer;
    try {
      _m3uProgress = 0.05;
      notifyListeners();
      simulationTimer = Timer.periodic(const Duration(milliseconds: 600), (
        timer,
      ) {
        if (_m3uProgress < 0.92) {
          _m3uProgress += 0.008;
          notifyListeners();
        } else {
          timer.cancel();
        }
      });
      final channels = await SupabaseService().parseM3UFromUrl(url);
      simulationTimer?.cancel();
      _m3uProgress = 0.95;
      notifyListeners();
      _externalChannels = channels;
      await Future.delayed(const Duration(milliseconds: 500));
      _m3uProgress = 1.0;
      sharedPrefs.setString('external_m3u_url', url);
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        _m3uProgress = 0.0;
        notifyListeners();
      });
    } catch (e) {
      simulationTimer?.cancel();
      _m3uProgress = 0.0;
      notifyListeners();
      debugPrint('Error loading external M3U: ${e}');
      rethrow;
    }
  }

  Future<void> loadSavedExternalM3U() async {
    final savedUrl = sharedPrefs.getString('external_m3u_url');
    final savedPath = sharedPrefs.getString('external_m3u_path');
    if (savedUrl != null && savedUrl!.isNotEmpty) {
      try {
        await loadExternalM3U(savedUrl);
      } catch (e) {
        debugPrint('Failed to load saved M3U URL on startup: ${e}');
      }
    } else if (savedPath != null && savedPath!.isNotEmpty) {
      try {
        await loadExternalM3UFromFile(savedPath);
      } catch (e) {
        debugPrint('Failed to load saved M3U File on startup: ${e}');
      }
    }
  }

  Future<void> loadExternalM3UFromFile(String path) async {
    Timer? simulationTimer;
    try {
      _m3uProgress = 0.05;
      notifyListeners();
      simulationTimer = Timer.periodic(const Duration(milliseconds: 300), (
        timer,
      ) {
        if (_m3uProgress < 0.92) {
          _m3uProgress += 0.05;
          notifyListeners();
        } else {
          timer.cancel();
        }
      });
      final channels = await SupabaseService().parseM3UFromFile(path);
      simulationTimer?.cancel();
      _m3uProgress = 0.95;
      notifyListeners();
      _externalChannels = channels;
      await Future.delayed(const Duration(milliseconds: 500));
      _m3uProgress = 1.0;
      sharedPrefs.remove('external_m3u_url');
      sharedPrefs.setString('external_m3u_path', path);
      notifyListeners();
      Future.delayed(const Duration(seconds: 2), () {
        _m3uProgress = 0.0;
        notifyListeners();
      });
    } catch (e) {
      simulationTimer?.cancel();
      _m3uProgress = 0.0;
      notifyListeners();
      debugPrint('Error loading external M3U file: ${e}');
      rethrow;
    }
  }

  void clearExternalM3U() {
    _externalChannels = [];
    sharedPrefs.remove('external_m3u_url');
    sharedPrefs.remove('external_m3u_path');
    notifyListeners();
  }
}
