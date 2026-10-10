import 'dart:convert';
import 'package:http/http.dart' as http;

class DynamicActivityPubOAuth {
  static const String redirectUri = 'feditok://login-callback';

  /// Estrae il dominio dall'input dell'utente (supporta sia '@user@domain.com' che 'domain.com')
  static String extractDomain(String input) {
    String clean = input.trim().toLowerCase();
    if (clean.startsWith('@')) {
      clean = clean.substring(1);
    }
    if (clean.contains('@')) {
      final parts = clean.split('@');
      return parts.last;
    }
    return clean;
  }

  /// 1. Registra dinamicamente l'applicazione su un'istanza Mastodon/ActivityPub
  static Future<Map<String, String>> registerOAuthApp(String instanceDomain) async {
    final url = Uri.parse('https://$instanceDomain/api/v1/apps');
    
    final response = await http.post(
      url,
      body: {
        'client_name': 'Feditok',
        'redirect_uris': redirectUri,
        'scopes': 'read write follow',
        'website': 'https://github.com/PiedinoTimido/Feditok',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return {
        'client_id': data['client_id'] as String,
        'client_secret': data['client_secret'] as String,
      };
    } else {
      throw Exception('Impossibile registrare l\'app OAuth sull\'istanza $instanceDomain (${response.statusCode})');
    }
  }

  /// 2. Costruisce l'URL di autorizzazione OAuth per l'utente
  static String getAuthorizationUrl({
    required String instanceDomain,
    required String clientId,
  }) {
    final Uri authUri = Uri.https(instanceDomain, '/oauth/authorize', {
      'client_id': clientId,
      'scope': 'read write follow',
      'redirect_uri': redirectUri,
      'response_type': 'code',
    });
    return authUri.toString();
  }

  /// 3. Scambia il codice di autorizzazione con l'Access Token
  static Future<String> getAccessToken({
    required String instanceDomain,
    required String clientId,
    required String clientSecret,
    required String code,
  }) async {
    final url = Uri.parse('https://$instanceDomain/oauth/token');

    final response = await http.post(
      url,
      body: {
        'client_id': clientId,
        'client_secret': clientSecret,
        'redirect_uri': redirectUri,
        'grant_type': 'authorization_code',
        'code': code,
        'scope': 'read write follow',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token'] as String;
    } else {
      throw Exception('Scambio token fallito: ${response.body}');
    }
  }

  /// 4. Recupera le informazioni dell'account dell'utente dal server federato (`/api/v1/accounts/verify_credentials`)
  static Future<Map<String, dynamic>> fetchFediverseProfile({
    required String instanceDomain,
    required String accessToken,
  }) async {
    final url = Uri.parse('https://$instanceDomain/api/v1/accounts/verify_credentials');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final username = data['username'] as String;
      final acct = data['acct'] as String;
      final fullHandle = acct.contains('@') ? '@$acct' : '@$username@$instanceDomain';

      return {
        'id': data['id'] as String,
        'username': username,
        'full_name': data['display_name'] as String? ?? username,
        'avatar_url': data['avatar'] as String?,
        'banner_url': data['header'] as String?,
        'bio': data['note'] as String?,
        'fediverse_handle': fullHandle,
        'instance': instanceDomain,
      };
    } else {
      throw Exception('Recupero profilo federato fallito: ${response.body}');
    }
  }
}
