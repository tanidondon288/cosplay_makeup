import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_data.dart';

/// アプリのデータ全体をブラウザ内へ保存し、読み込む。
class AppStorage {
  static const _storageKey = 'cosplay_makeup_v1';

  /// 保存済みのデータを読み込む。保存データがない・壊れているときは null。
  Future<AppData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonText = prefs.getString(_storageKey);
    if (jsonText == null) return null;
    try {
      return AppData.fromJson(jsonDecode(jsonText) as Map<String, dynamic>);
    } on FormatException catch (error) {
      debugPrint('保存データを読み込めませんでした: $error');
      return null;
    } on TypeError catch (error) {
      debugPrint('保存データを読み込めませんでした: $error');
      return null;
    }
  }

  Future<void> save(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(data.toJson()));
  }
}
