import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class FirebaseRemoteConfigSyncService {
  static const String defaultProjectId = 'box-cricket-df427';

  static const String defaultServiceAccountJson = '';

  /// Publishes parameters directly to Firebase Remote Config REST API v1.
  static Future<({bool success, String message})> publishToFirebase({
    required Map<String, String> parameters,
    String? serviceAccountJsonString,
    String? accessToken,
    String projectId = defaultProjectId,
  }) async {
    try {
      String? token = accessToken?.trim();

      String jsonToUse = (serviceAccountJsonString != null && serviceAccountJsonString.trim().isNotEmpty)
          ? serviceAccountJsonString.trim()
          : defaultServiceAccountJson;

      if (token == null || token.isEmpty) {
        try {
          dynamic decoded = jsonDecode(jsonToUse);
          if (decoded is String) {
            decoded = jsonDecode(decoded);
          }
          final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(decoded as Map);

          final credentials = ServiceAccountCredentials.fromJson(jsonMap);
          final scopes = ['https://www.googleapis.com/auth/firebase.remoteconfig'];

          final httpClient = http.Client();
          final authClient = await clientViaServiceAccount(
            credentials,
            scopes,
            baseClient: httpClient,
          );
          token = authClient.credentials.accessToken.data;
          authClient.close();
        } catch (e) {
          debugPrint('❌ Service Account Auth Error: $e');
          return (
            success: false,
            message: 'Service Account JSON Error: $e. Make sure you copied the complete JSON file content.'
          );
        }
      }

      if (token.isEmpty) {
        return (
          success: false,
          message: 'No Service Account Key or Access Token provided.'
        );
      }

      final url = Uri.parse(
        'https://firebaseremoteconfig.googleapis.com/v1/projects/$projectId/remoteConfig',
      );

      final Map<String, dynamic> paramMap = {};
      parameters.forEach((key, value) {
        String valueType = 'STRING';
        final valLower = value.trim().toLowerCase();
        if (valLower == 'true' || valLower == 'false') {
          valueType = 'BOOLEAN';
        } else if (double.tryParse(value) != null && !key.contains('version')) {
          valueType = 'NUMBER';
        }

        paramMap[key] = {
          'defaultValue': {'value': value},
          'valueType': valueType,
        };
      });

      final body = jsonEncode({'parameters': paramMap});

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json; charset=utf-8',
          'If-Match': '*',
        },
        body: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ FIREBASE REMOTE CONFIG PUBLISHED SUCCESSFULLY!');
        return (
          success: true,
          message: '🔥 Successfully published 15 parameters to Firebase Remote Config!'
        );
      } else {
        debugPrint('❌ FIREBASE REMOTE CONFIG PUBLISH FAILED [${response.statusCode}]: ${response.body}');
        return (
          success: false,
          message: 'Firebase API Error [${response.statusCode}]: ${response.body}'
        );
      }
    } catch (e) {
      debugPrint('❌ FIREBASE REMOTE CONFIG SYNC ERROR: $e');
      return (
        success: false,
        message: 'Sync Error: $e'
      );
    }
  }
}
