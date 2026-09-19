import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

class FirebaseRemoteConfigSyncService {
  static const String defaultProjectId = 'box-cricket-df427';

  static const String defaultServiceAccountJsonBase64 = 'eyJ0eXBlIjoic2VydmljZV9hY2NvdW50IiwicHJvamVjdF9pZCI6ImJveC1jcmlja2V0LWRmNDI3IiwicHJpdmF0ZV9rZXlfaWQiOiI1ZWIxMjM3MzY5M2I3MTY3NjZjMjRiZGQ0NDE2YWM5NDc4NWI4OWRkIiwicHJpdmF0ZV9rZXkiOiItLS0tLUJFR0lOIFBSSVZBVEUgS0VZLS0tLS1cbk1JSUV2UUlCQURBTkJna3Foa2lHOXcwQkFRRUZBQVNDQktjd2dnU2pBZ0VBQW9JQkFRRDBXa29JODRENW1qNkNcbkJNSjBuV254UzZ0V21BRmNVNTU1VTcwZ2N5N0JXYVA3UFc1U0Y0WVV4UnJoQmZGMUVZdHdOQTVGbGplanNkTEpcbm5tWFFidW5GRmNlQkdocVhJdDB4SG9jWWVaNVBkNFhRbjVxdS9IZ2JRU2RKeFVZNFBvOW53a2RUblRETUpqR3hcbkdoNzgydzIxcW9PS2dINU9ROTBaOFBvbDhnYmZvcjF4TTRIVTZHTnlodGdJNTNDcm5VK0UvM1Rxb2k4VzNvMG1cblZtR20ydUlqUlhpblhnL1lVV0FGQklSRmxyVzV4ejNycG5keXpCOXBqU2VtMjNJREpvNVRZTHpMVDFsVkREWldcbmVScWxKWk5NODE4Z29YNUNiRERrS0t2bHhxM0hsT1ZEd0Y5b1h3NHpBSTJpYUJVWi9IWEJQbXUwK1gyRkllUmtcblIvdUlTK1QvQWdNQkFBRUNnZ0VBSWVoR00ycklLc1ZteDNldDhpMEdlVklxUXZobk5wbHdqclBQaXBRTDJMbTlcbjF3eGx1cytDaEJtbWlyT0pRaTVUNlVIWCtkRUlCSUpBVnA1UkpqVEFqTFdOSmRMcVUxbW1WRkxBK3JwTy9RWlZcbmFVckZWZzNqcnNpQ1BBQTdmUmVLb25mT1JRSGdObkZWczVhRksvVDJZem4zbnoyekNUSkNtVlJ4VklMNnhZZStcbnUwTXBHTDBBalFmdlR4YmhESE4rajVtZ3RrRThzamZhZjBrbWtnNXVLSlFpaC9aOTJmczR0Q0phTkJEK1NUUUhcbktBUllBQytRcUdsRGRHY1FNZk9PSlQyc2F6azlyTHlUU1VxOUMwdE1XUGpPL3h5RlhVVU1OaXJpcEMxZnRoeXZcbkFXUldaQmo0QU5LZkxhdHNhc1ltSUFwbWlZSHhTVmd4T3JjdHMyVjBVUUtCZ1FEL2VFbG0zRDFJSTB6cmZzUzBcbnp1dlpCWHY0ZE9yZHBlZVlGb1d3WW43N0p2eDJqVnpCeVVZYkkzVWN3QlUrRDhkZVEvRkIrUVNXSWxLRWFqRmhcbk9VQVh2UTMvU3pwUFhtWXhpbHpjWjhkdDViRU9kcW9MNGNGcHFZYkVZcHNtYlJlNlNrcU9ITzRwL29QTjVabnBcblc5NnUyT2xlYzhJVXgrMVYzbWRvWlJ5cVR3S0JnUUQwM0JqQTlKcEdOclZGbzFrWGxYOEZ5SDhRQXNyQ2h5N1Zcblh0VWhUcWNIUWxVcWR6OFEvUUNuOGRmajZkK1hRSXFGUjA3M3lNb3B6SkZwM042aC9yRnIzMXo5MzJoSkorMWlcbkFDNnBsOXI3ZDJtbW1tbk1EMHI1cUlJWnJ1THNnWUgyMExMcDVraVZKYTFMSUxBUkdRNjBubXlGbkw4WHd6RkVcbkM2cS84ZjllVVFLQmdRRE4yOVg2SnZyU3lHOVJUTU9obHlRQnF5T3NvRG9xQldoTDY4b3F5aFBjdWh1eVJGTThcbmJMNHJYRFVneDcvV1ZNeW9yME1Ya0Z3Ynh1aUxmeTd2VXp6TVpER0ZTTTloNllXYjRneldKbUpUc2tVc2pINldcbk9JS3NiRWtHc3hhbXJqM3loYTd5T1duSk9TaG9uOTJZWjhsWFI3ODF0ejNybFBjd3ZKakRUTWIralFLQmdIYmlcbjFuSDVVVjU5K1kyU1BoT2hWa2NzamVUc05oNDFISndrcXo2OHZZUmN4SlVWeU4wcXVrTFF2WTIvWS94QUxnR0FcbkdldGM1aXRkVTgwZW5FbnpLNW5BblpuMSt1QnFMbXZDd3VVOUFlbk9sTkY3YjVyUVlnck5zajFlR0hmVWVaR29cbnl2V2VCZWZFbjFzMng4WEZjTXBwa1M5ZVo3blYzL20xNEhYSnZiL0JBb0dBUFZkVnRFTTUxRXFLWTRjTHlwWFJcbno0MENnTGFXTlFDZWVzUGlzZkFhdVNNSnlBL1NzalQ4ckJ6ZFdXZjhBc2JReit2VTRjbkxlYktOVUpjYWZIUG1cbnBaNUUvZjV1d3pXclNiZFpja3JhVkZzaUdQMUFDaWJ1UHNSMGxObldETVVVQWp5RG9MS0NhdjNFMG54Y2JsbVdcbnI3UlZ4eVRCMy80cERFMTdJc1NVc1hzPVxuLS0tLS1FTkQgUFJJVkFURSBLRVktLS0tLVxuIiwiY2xpZW50X2VtYWlsIjoiZmlyZWJhc2UtYWRtaW5zZGstZmJzdmNAYm94LWNyaWNrZXQtZGY0MjcuaWFtLmdzZXJ2aWNlYWNjb3VudC5jb20iLCJjbGllbnRfaWQiOiIxMDM1NzQ2MDI2OTg4NDY3MDIwMjciLCJhdXRoX3VyaSI6Imh0dHBzOi8vYWNjb3VudHMuZ29vZ2xlLmNvbS9vL29hdXRoMi9hdXRoIiwidG9rZW5fdXJpIjoiaHR0cHM6Ly9vYXV0aDIuZ29vZ2xlYXBpcy5jb20vdG9rZW4iLCJhdXRoX3Byb3ZpZGVyX3g1MDlfY2VydF91cmwiOiJodHRwczovL3d3dy5nb29nbGVhcGlzLmNvbS9vYXV0aDIvdjEvY2VydHMiLCJjbGllbnRfeDUwOV9jZXJ0X3VybCI6Imh0dHBzOi8vd3d3Lmdvb2dsZWFwaXMuY29tL3JvYm90L3YxL21ldGFkYXRhL3g1MDkvZmlyZWJhc2UtYWRtaW5zZGstZmJzdmMlNDBib3gtY3JpY2tldC1kZjQyNy5pYW0uZ3NlcnZpY2VhY2NvdW50LmNvbSIsInVuaXZlcnNlX2RvbWFpbiI6Imdvb2dsZWFwaXMuY29tIn0=';
 
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
           : utf8.decode(base64Decode(defaultServiceAccountJsonBase64));

      if (jsonToUse.isEmpty) {
        return (
          success: false,
          message: 'Please paste your Firebase Service Account JSON. The field is currently empty!'
        );
      }

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
