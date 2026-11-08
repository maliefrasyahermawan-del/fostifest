import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LarasApiException implements Exception {
  const LarasApiException(
    this.message, {
    this.status = 0,
    this.code = 'network',
  });
  final String message, code;
  final int status;
  @override
  String toString() => message;
}

/// Configured builds use the server explicitly, without a silent local fallback.
class LarasApi {
  LarasApi({http.Client? client, Uri? baseUri})
      : _client = client,
        _baseUri = baseUri;
  static const enabled = bool.fromEnvironment(
    'LARAS_BACKEND',
    defaultValue: false,
  );
  static const _configuredUrl = String.fromEnvironment('LARAS_API_URL');
  final http.Client? _client;
  final Uri? _baseUri;
  Uri get baseUri {
    final uri = _baseUri ??
        (_configuredUrl.isNotEmpty
            ? Uri.parse(_configuredUrl)
            : kIsWeb
                ? Uri.base.resolve('/api/')
                : Uri.parse('http://127.0.0.1:8080/api/'));
    if (!['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw const LarasApiException(
        'Alamat backend belum valid.',
        code: 'configuration',
      );
    }
    return Uri.parse('${uri.toString().replaceAll(RegExp(r'/+$'), '')}/');
  }

  String get _prefix => 'laras_server_v1_${baseUri.toString()}';
  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = true,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('${_prefix}token');
    if (authenticated && token == null) {
      throw const LarasApiException(
        'Masuk ulang untuk membuka simpanan server.',
        status: 401,
        code: 'unauthorized',
      );
    }
    final request = http.Request(method, baseUri.resolve(path));
    request.headers['Accept'] = 'application/json';
    if (authenticated) request.headers['Authorization'] = 'Bearer $token';
    if (body != null) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode(body);
    }
    final client = _client ?? http.Client();
    try {
      final response = await (() async => http.Response.fromStream(
                await client.send(request),
              ))()
          .timeout(const Duration(seconds: 20));
      Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(
          jsonDecode(utf8.decode(response.bodyBytes)) as Map,
        );
      } catch (_) {
        throw const LarasApiException(
          'Respons backend tidak valid. Periksa alamat server.',
          code: 'invalid_response',
        );
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = data['error'] as Map?;
        throw LarasApiException(
          '${error?['message'] ?? 'Permintaan belum berhasil. Coba lagi.'}',
          status: response.statusCode,
          code: '${error?['code'] ?? 'server_error'}',
        );
      }
      return data;
    } on TimeoutException {
      throw const LarasApiException(
        'Server belum merespons. Coba lagi; simpanan yang sama tidak digandakan.',
      );
    } on http.ClientException {
      throw const LarasApiException(
        'Backend tidak terhubung. Pastikan server LARAS sedang berjalan.',
      );
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<void> _storeSession(Map<String, dynamic> data) async {
    if (data['token'] is! String || data['user'] is! Map) {
      throw const LarasApiException(
        'Respons sesi tidak valid.',
        code: 'invalid_response',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString('${_prefix}token', data['token'] as String)) {
      throw const LarasApiException(
        'Sesi belum bisa disimpan di perangkat ini.',
      );
    }
    await prefs.setBool('${_prefix}guest', data['guest'] == true);
    await prefs.setString('${_prefix}user', jsonEncode(data['user']));
    // The server build never retains the legacy plaintext password.
    await prefs.remove('account_password');
  }

  Future<void> login(String identifier, String password) async => _storeSession(
        await request(
          'POST',
          'auth/login',
          authenticated: false,
          body: {'identifier': identifier, 'password': password},
        ),
      );
  Future<void> register(
    String name,
    String identifier,
    String password,
  ) async =>
      _storeSession(
        await request(
          'POST',
          'auth/register',
          authenticated: false,
          body: {
            'fullName': name,
            'identifier': identifier,
            'password': password
          },
        ),
      );
  Future<void> enterGuest() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('${_prefix}guest') == true &&
        prefs.containsKey('${_prefix}token')) {
      try {
        await request('GET', 'auth/me');
        return;
      } on LarasApiException catch (e) {
        if (e.status != 401) rethrow;
      }
    }
    await _storeSession(
      await request('POST', 'auth/guest', body: {}, authenticated: false),
    );
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (prefs.containsKey('${_prefix}token')) {
        await request('POST', 'auth/logout', body: {});
      }
    } finally {
      await prefs.remove('${_prefix}token');
      await prefs.remove('${_prefix}guest');
      await prefs.remove('${_prefix}user');
    }
  }
}
