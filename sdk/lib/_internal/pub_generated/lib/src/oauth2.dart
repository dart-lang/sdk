library pub.oauth2;
import 'dart:async';
import 'dart:io';
import 'package:oauth2/oauth2.dart';
import 'package:path/path.dart' as path;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'http.dart';
import 'io.dart';
import 'log.dart' as log;
import 'system_cache.dart';
import 'utils.dart';
export 'package:oauth2/oauth2.dart';
final _identifier =
    '818368855108-8grd2eg9tj9f38os6f1urbcvsq399u8n.apps.' 'googleusercontent.com';
final _secret = 'SWeqj8seoJW0w7_CpEPFLX0K';
final authorizationEndpoint = Uri.parse(
    'https://accounts.google.com/o/oauth2/auth?access_type=offline'
        '&approval_prompt=force');
Uri get tokenEndpoint {
  var tokenEndpoint = Platform.environment['_PUB_TEST_TOKEN_ENDPOINT'];
  if (tokenEndpoint != null) {
    return Uri.parse(tokenEndpoint);
  } else {
    return _tokenEndpoint;
  }
}
final _tokenEndpoint = Uri.parse('https://accounts.google.com/o/oauth2/token');
final _scopes = ['https://www.googleapis.com/auth/userinfo.email'];
Credentials _credentials;
void clearCredentials(SystemCache cache) {
  _credentials = null;
  var credentialsFile = _credentialsFile(cache);
  if (entryExists(credentialsFile)) deleteEntry(credentialsFile);
}
Future withClient(SystemCache cache, Future fn(Client client)) {
  return _getClient(cache).then((client) {
    var completer = new Completer();
    return fn(client).whenComplete(() {
      client.close();
      _saveCredentials(cache, client.credentials);
    });
  }).catchError((error) {
    if (error is ExpirationException) {
      log.error(
          "Pub's authorization to upload packages has expired and "
              "can't be automatically refreshed.");
      return withClient(cache, fn);
    } else if (error is AuthorizationException) {
      var message = "OAuth2 authorization failed";
      if (error.description != null) {
        message = "$message (${error.description})";
      }
      log.error("$message.");
      clearCredentials(cache);
      return withClient(cache, fn);
    } else {
      throw error;
    }
  });
}
Future<Client> _getClient(SystemCache cache) {
  return new Future.sync(() {
    var credentials = _loadCredentials(cache);
    if (credentials == null) return _authorize();
    var client =
        new Client(_identifier, _secret, credentials, httpClient: httpClient);
    _saveCredentials(cache, client.credentials);
    return client;
  });
}
Credentials _loadCredentials(SystemCache cache) {
  log.fine('Loading OAuth2 credentials.');
  try {
    if (_credentials != null) return _credentials;
    var path = _credentialsFile(cache);
    if (!fileExists(path)) return null;
    var credentials = new Credentials.fromJson(readTextFile(path));
    if (credentials.isExpired && !credentials.canRefresh) {
      log.error(
          "Pub's authorization to upload packages has expired and "
              "can't be automatically refreshed.");
      return null;
    }
    return credentials;
  } catch (e) {
    log.error(
        'Warning: could not load the saved OAuth2 credentials: $e\n'
            'Obtaining new credentials...');
    return null;
  }
}
void _saveCredentials(SystemCache cache, Credentials credentials) {
  log.fine('Saving OAuth2 credentials.');
  _credentials = credentials;
  var credentialsPath = _credentialsFile(cache);
  ensureDir(path.dirname(credentialsPath));
  writeTextFile(credentialsPath, credentials.toJson(), dontLogContents: true);
}
String _credentialsFile(SystemCache cache) =>
    path.join(cache.rootDir, 'credentials.json');
Future<Client> _authorize() {
  var grant = new AuthorizationCodeGrant(
      _identifier,
      _secret,
      authorizationEndpoint,
      tokenEndpoint,
      httpClient: httpClient);
  var completer = new Completer();
  bindServer('localhost', 0).then((server) {
    shelf_io.serveRequests(server, (request) {
      if (request.url.path != "/") {
        return new shelf.Response.notFound('Invalid URI.');
      }
      log.message('Authorization received, processing...');
      var queryString = request.url.query;
      if (queryString == null) queryString = '';
      server.close();
      chainToCompleter(
          grant.handleAuthorizationResponse(queryToMap(queryString)),
          completer);
      return new shelf.Response.found('http://pub.dartlang.org/authorized');
    });
    var authUrl = grant.getAuthorizationUrl(
        Uri.parse('http://localhost:${server.port}'),
        scopes: _scopes);
    log.message(
        'Pub needs your authorization to upload packages on your behalf.\n'
            'In a web browser, go to $authUrl\n' 'Then click "Allow access".\n\n'
            'Waiting for your authorization...');
  });
  return completer.future.then((client) {
    log.message('Successfully authorized.\n');
    return client;
  });
}
