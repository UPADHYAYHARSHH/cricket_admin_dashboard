import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:googleapis_auth/auth_io.dart';

void main() async {
  print('🚀 Testing Firebase Remote Config Publishing...');

  final serviceAccountJson = r'''{
  "type": "service_account",
  "project_id": "box-cricket-df427",
  "private_key_id": "928976bf9a022c02a3ae5483fd2f9bdcad7c2924",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQDA4cWRjcBJR8jW\neXsKG2p8i4CCxiXo7m+RTYgPKMCAiNWt10i0zuPDfusCAsm7QenmC3uyKhnSTD/0\nDlJ8RfLN4ye7W7mb7GBGaj+h5tclvPQbK2WPP/vv/xWGHtzPEKGFfKjUzgyC/WPX\nklT2GOvQNIXXQASS5E8YNFIpPjsJFa26Zq40E8IRJ30f2bv+5yWnnARHPdIjE3Ly\n86YyTwKmSm+xRr04AFgYeOpBwhqqVgPkgbjCJzmHqMK5oQPXgSsQfCcZEL4dtXwx\nqZkC1tAwN4+X/WJtowBhAmr1UHocqaoLt5XNHhLLb21C9WQZztscwvb5PKamL6zb\nOxbEc71hAgMBAAECggEAJs1EcYOSqytFu9+0YNQjF+r4b1ZtSe6tgw2V0XbhQvpE\nAjTM65KzPyDJJh5pdsJLy3uD5tORXjz4oKBA978amVCZLZfGPxfORlwZcPh/T5gz\ng0O3qpm0lRM7wT90LDOsSq5JSIYq/i77ZuKJNPjOd5QZWLQIN4S2ZKgh3yolti3M\nnsVWWTlaYO8ouOVm0+UuL+8WuOpxCTLsa0FjnuBMZDjBHXki5OHVCAHg9EI+AUtW\nBe9jRsM0XkyLiEu71atGOA7ynAxynRauRaW8mz41CQgjsZEfTcedrGb99xP7EX9c\nviHjsue2alV/idNOEyH0ZklpJ3EgaCaG8U/kbWTOAQKBgQDvRux0ZgBOQm1eo/tN\nJpIZRPq33WaJdzopC8OhDdN+L7des5pdQcC9z+8EqvcyxIZZGMsGpxMnKx7GTOqT\nguILEqDd2gBedAwpu3gFsMAJUUQSKSL1dh17zoYWgtZBDUSya/DNNGo2Anfh8brl\nvICjU25l7EGn405L5fGz15HYZwKBgQDOXMKDxlCWF9y6SeLJsZMk1GRGqnCQ/SuC\ne2yf2xYEYBsKWIDfYQfMbCH0sXLwhy7nWoVt8pBwKFO8pC7m+6ERorolnYdj07u+\nBzQEY5Z19CHYRg+I8wmlHZRcj/RHPrnRJgRDOMqr9/V9CgcT/K8A8mHvypsnR7d0\nYPWzwTU+9wKBgAWUKb8tAaTRd6tVN269D3r3WMEgsFtUJE8Arzb6E4xFoIjctySl\ne9DxICmDsu/EFT3Oji1Bh/jJ0JXfBTkbPBn1/Tou8wNAwWfXrxyy2kddVbD2tJH0\nhwtz7TxpIIWzwX5Hdf3S0wcfV5w0/p6MnpMwRsqpj35Slmi+m7wNsqDRAoGABV//\nJQWGVdJ7SlLgWFaKuZvanMiVtAEUIArs8mD3etex/Jv/h1H0rQtn+wKgNsmenCIM\ndaeqwXEbdT9lhViqglYVuSMYQq5iJnnzjeW2Jo5cT1DL2MpTxvw1QA/z0eM9Xcg6\ntjGFfeMwfrhDJO8g88pcaK2DSwugKKTZ4Xu30lMCgYEA5v6Yu+lLp7erwsCAAQu3\nl+T3tn3aBVJTvncxwHPlur29OuqC7xQqty3CSK+WZOoXno8cXwFPyEsvBz4T4kqU\n4sHX+bTOSt8W3DvW3X5DhcPpWEQRE3buVibzI246v6h+19BBcl12K1fwf9tZMpan\nbfku7h3ljxaJcKaVxaArBZw=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@box-cricket-df427.iam.gserviceaccount.com",
  "client_id": "103574602698846702027",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40box-cricket-df427.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}''';

  try {
    final credentials = ServiceAccountCredentials.fromJson(jsonDecode(serviceAccountJson));
    final scopes = ['https://www.googleapis.com/auth/firebase.remoteconfig'];

    final httpClient = http.Client();
    final authClient = await clientViaServiceAccount(credentials, scopes, baseClient: httpClient);
    final token = authClient.credentials.accessToken.data;
    authClient.close();

    print('🔑 ACCESS TOKEN OBTAINED: ${token.substring(0, 20)}...');

    final url = Uri.parse('https://firebaseremoteconfig.googleapis.com/v1/projects/box-cricket-df427/remoteConfig');

    final Map<String, dynamic> parameters = {
      'is_under_maintenance': {'defaultValue': {'value': 'false'}, 'valueType': 'BOOLEAN'},
      'required_version': {'defaultValue': {'value': '1.0.0'}, 'valueType': 'STRING'},
      'platform_fee': {'defaultValue': {'value': '25'}, 'valueType': 'NUMBER'},
      'commission_rate': {'defaultValue': {'value': '10'}, 'valueType': 'NUMBER'},
      'commission_is_percentage': {'defaultValue': {'value': 'true'}, 'valueType': 'BOOLEAN'},
      'user_app_maintenance': {'defaultValue': {'value': 'false'}, 'valueType': 'BOOLEAN'},
      'owner_app_maintenance': {'defaultValue': {'value': 'false'}, 'valueType': 'BOOLEAN'},
      'user_android_min_version': {'defaultValue': {'value': '1.0.0'}, 'valueType': 'STRING'},
      'user_ios_min_version': {'defaultValue': {'value': '1.0.0'}, 'valueType': 'STRING'},
      'user_android_store_url': {'defaultValue': {'value': 'https://play.google.com/store/apps/details?id=com.boxcricket.booking'}, 'valueType': 'STRING'},
      'user_ios_store_url': {'defaultValue': {'value': 'https://apps.apple.com'}, 'valueType': 'STRING'},
      'owner_android_min_version': {'defaultValue': {'value': '1.0.0'}, 'valueType': 'STRING'},
      'owner_ios_min_version': {'defaultValue': {'value': '1.0.0'}, 'valueType': 'STRING'},
      'owner_android_store_url': {'defaultValue': {'value': 'https://play.google.com/store/apps/details?id=com.example.box_cricket_booking_owner'}, 'valueType': 'STRING'},
      'owner_ios_store_url': {'defaultValue': {'value': 'https://apps.apple.com'}, 'valueType': 'STRING'},
    };

    final body = jsonEncode({'parameters': parameters});

    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json; charset=utf-8',
        'If-Match': '*',
      },
      body: body,
    );

    print('RESPONSE STATUS: ${response.statusCode}');
    print('RESPONSE BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('🎉 SUCCESS! ALL 15 VARIABLES PUBLISHED TO FIREBASE REMOTE CONFIG!');
    }
  } catch (e, stack) {
    print('❌ ERROR: $e');
    print(stack);
  }
}
