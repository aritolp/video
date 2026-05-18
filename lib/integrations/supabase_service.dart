import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tvplus/globals/app_constants.dart';
import 'package:tvplus/models/lista_de_canales.dart';
import 'package:tvplus/main.dart';
import 'package:flutter/material.dart';
import 'package:tvplus/models/app_info.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

@NowaGenerated()
class SupabaseService {
  SupabaseService._();

  factory SupabaseService() {
    return _instance;
  }

  static final SupabaseService _instance = SupabaseService._();

  Future<AuthResponse> signIn(String email, String password) async {
    return Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  Future initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  Future<List<listaDeCanales>> getAllCanales() async {
    final response = await Supabase.instance.client.from('canales').select('*');
    return response.map((json) => listaDeCanales.fromJson(json)).toList();
  }

  Future<AuthResponse> signUpWithProfile(
    String email,
    String password,
    String nombre,
  ) async {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
    );
    if (response.user != null) {
      await Supabase.instance.client.from('profiles').insert({
        'id': response.user?.id,
        'nombre': nombre,
        'preferencia_canal': null,
      });
    }
    return response;
  }

  Future<void> updateLastChannel(int channelId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await Supabase.instance.client
          .from('profiles')
          .update({'preferencia_canal': channelId})
          .eq('id', user.id);
    }
  }

  Future<bool> signInWithCode(String code) async {
    try {
      final response = await Supabase.instance.client
          .from('codigos_acceso')
          .select()
          .eq('codigo', code)
          .maybeSingle();
      if (response != null) {
        await sharedPrefs.setBool('bypass_auth', true);
        return true;
      }
    } catch (e) {
      debugPrint('Error validando código: ${e}');
    }
    return false;
  }

  Future<List<int>> getFavorites() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return [];
    }
    try {
      final response = await Supabase.instance.client
          .from('favoritos')
          .select('channel_id')
          .eq('user_id', user.id);
      return List<int>.from(response.map((f) => f['channel_id'] as int));
    } catch (e) {
      debugPrint('Error fetching favorites: ${e}');
      return [];
    }
  }

  Future<void> addFavorite(int channelId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      await Supabase.instance.client.from('favoritos').upsert({
        'user_id': user.id,
        'channel_id': channelId,
      });
    } catch (e) {
      debugPrint('Error adding favorite: ${e}');
    }
  }

  Future<void> removeFavorite(int channelId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      await Supabase.instance.client
          .from('favoritos')
          .delete()
          .eq('user_id', user.id)
          .eq('channel_id', channelId);
    } catch (e) {
      debugPrint('Error removing favorite: ${e}');
    }
  }

  Future<AppInfo?> getAppInfo() async {
    try {
      final response = await Supabase.instance.client
          .from('app_config')
          .select()
          .limit(1)
          .maybeSingle();
      if (response != null) {
        return AppInfo.fromJson(response);
      }
    } catch (e) {
      debugPrint('Error fetching app info: ${e}');
    }
    return null;
  }

  Future<List<listaDeCanales>> parseM3UFromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return parseM3UString(response.body);
      }
      throw Exception('Error cargando M3U: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error en parseM3UFromUrl: ${e}');
      rethrow;
    }
  }

  List<listaDeCanales> parseM3UString(String content) {
    final List<listaDeCanales> channels = [];
    final List<String> lines = content.split('\n');
    String? currentName;
    String? currentLogo;
    String? currentGroup;
    int tempId = -1000;
    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('#EXTINF:')) {
        final commaIndex = line.lastIndexOf(',');
        if (commaIndex != -1) {
          currentName = line.substring(commaIndex + 1).trim();
        }
        final logoMatch = RegExp('tvg-logo="([^"]+)"').firstMatch(line);
        currentLogo = logoMatch?.group(1);
        final groupMatch = RegExp('group-title="([^"]+)"').firstMatch(line);
        currentGroup = groupMatch?.group(1);
      } else if (line.isNotEmpty && !line.startsWith('#')) {
        if (currentName != null) {
          channels.add(
            listaDeCanales(
              id: tempId--,
              nombre: currentName,
              url_stream: line,
              logo: currentLogo,
              categoria: 'M3U',
            ),
          );
        }
        currentName = null;
        currentLogo = null;
        currentGroup = null;
      }
    }
    return channels;
  }

  Future<List<listaDeCanales>> parseM3UFromFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        final content = await file.readAsString();
        return parseM3UString(content);
      }
      throw Exception('El archivo no existe en la ruta proporcionada');
    } catch (e) {
      debugPrint('Error en parseM3UFromFile: ${e}');
      rethrow;
    }
  }
}
