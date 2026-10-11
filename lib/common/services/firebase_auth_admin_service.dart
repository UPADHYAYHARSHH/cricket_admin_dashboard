import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';
import 'package:cricket_admin_panel/common/services/firebase_remote_config_sync_service.dart';

class FirebaseAuthAdminService {
  /// Fetches all users from Firebase Auth using Identity Toolkit batchGet.
  /// Handles pagination with page tokens.
  static Future<List<Map<String, dynamic>>> fetchFirebaseUsers({
    String? serviceAccountJsonString,
    String projectId = FirebaseRemoteConfigSyncService.defaultProjectId,
  }) async {
    final List<Map<String, dynamic>> firebaseUsers = [];

    try {
      final String jsonToUse = (serviceAccountJsonString != null && serviceAccountJsonString.trim().isNotEmpty)
          ? serviceAccountJsonString.trim()
          : utf8.decode(base64Decode(FirebaseRemoteConfigSyncService.defaultServiceAccountJsonBase64));

      dynamic decoded = jsonDecode(jsonToUse);
      if (decoded is String) {
        decoded = jsonDecode(decoded);
      }
      final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(decoded as Map);
      final credentials = ServiceAccountCredentials.fromJson(jsonMap);

      final httpClient = http.Client();
      final authClient = await clientViaServiceAccount(
        credentials,
        [
          'https://www.googleapis.com/auth/identitytoolkit',
          'https://www.googleapis.com/auth/cloud-platform',
        ],
        baseClient: httpClient,
      );

      String? nextPageToken;
      do {
        final queryParams = <String, String>{
          'maxResults': '100',
        };
        if (nextPageToken != null && nextPageToken.isNotEmpty) {
          queryParams['nextPageToken'] = nextPageToken;
        }

        final uri = Uri.https(
          'identitytoolkit.googleapis.com',
          '/v1/projects/$projectId/accounts:batchGet',
          queryParams,
        );

        final response = await authClient.get(uri);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final usersList = data['users'] as List<dynamic>?;
          if (usersList != null) {
            for (final u in usersList) {
              if (u is Map<String, dynamic>) {
                firebaseUsers.add(u);
              }
            }
          }
          nextPageToken = data['nextPageToken'] as String?;
        } else {
          debugPrint('⚠️ [FirebaseAuthAdminService] Error fetching users: ${response.statusCode} ${response.body}');
          break;
        }
      } while (nextPageToken != null && nextPageToken.isNotEmpty);

      authClient.close();
    } catch (e) {
      debugPrint('⚠️ [FirebaseAuthAdminService] Exception: $e');
    }

    return firebaseUsers;
  }
}
