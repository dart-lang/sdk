// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library oauth2;

import 'dart:io';
import 'dart:uri';

// TODO(nweiz): Make this a "package:" URL, or something nicer than this.
import '../../pkg/oauth2/lib/oauth2.dart';
import 'curl_client.dart';
import 'io.dart';
import 'system_cache.dart';
import 'utils.dart';

export '../../pkg/oauth2/lib/oauth2.dart';

/// The pub client's OAuth2 identifier.
final _identifier = '818368855108-8grd2eg9tj9f38os6f1urbcvsq399u8n.apps.'
    'googleusercontent.com';

/// The pub client's OAuth2 secret. This isn't actually meant to be kept a
/// secret.
final _secret = 'SWeqj8seoJW0w7_CpEPFLX0K';

/// The URL to which the user will be directed to authorize the pub client to
/// get an OAuth2 access token.
///
/// `access_type=offline` and `approval_prompt=force` ensures that we always get
/// a refresh token from the server. See the [Google OAuth2 documentation][].
///
/// [Google OAuth2 documentation]: https://developers.google.com/accounts/docs/OAuth2WebServer#offline
final _authorizationEndpoint = new Uri.fromString(
    'https://accounts.google.com/o/oauth2/auth?access_type=offline'
    '&approval_prompt=force');

/// The URL from which the pub client will request an access token once it's
/// been authorized by the user.
final _tokenEndpoint = new Uri.fromString(
    'https://accounts.google.com/o/oauth2/token');

/// The OAuth2 scopes that the pub client needs. Currently the client only needs
/// the user's email so that the server can verify their identity.
final _scopes = ['https://www.googleapis.com/auth/userinfo.email'];

/// An in-memory cache of the user's OAuth2 credentials. This should always be
/// the same as the credentials file stored in the system cache.
Credentials _credentials;

/// Asynchronously passes an OAuth2 [Client] to [fn], and closes the client when
/// the [Future] returned by [fn] completes.
///
/// This takes care of loading and saving the client's credentials, as well as
/// prompting the user for their authorization.
Future withClient(SystemCache cache, Future fn(Client client)) {
  return _getClient(cache).chain((client) {
    var completer = new Completer();
    var future = fn(client);
    future.onComplete((_) {
      try {
        client.close();
        // Be sure to save the credentials even when an error happens. Also be
        // sure to pipe the exception from `future` to `completer`.
        chainToCompleter(
            _saveCredentials(cache, client.credentials).chain((_) => future),
            completer);
      } catch (e, stackTrace) {
        // onComplete will drop exceptions on the floor. We want to ensure that
        // any programming errors here don't go un-noticed. See issue 4127.
        completer.completeException(e, stackTrace);
      }
    });
    return completer.future;
  });
}

/// Gets a new OAuth2 client. If saved credentials are available, those are
/// used; otherwise, the user is prompted to authorize the pub client.
Future<Client> _getClient(SystemCache cache) {
  var httpClient = new CurlClient();

  return _loadCredentials(cache).chain((credentials) {
    if (credentials != null) {
      return new Future.immediate(new Client(
          _identifier, _secret, credentials, httpClient: httpClient));
    }

    // Allow the tests to inject their own token endpoint URL.
    var tokenEndpoint = Platform.environment['_PUB_TEST_TOKEN_ENDPOINT'];
    if (tokenEndpoint != null) {
      tokenEndpoint = new Uri.fromString(tokenEndpoint);
    } else {
      tokenEndpoint = _tokenEndpoint;
    }

    var grant = new AuthorizationCodeGrant(
        _identifier,
        _secret,
        _authorizationEndpoint,
        tokenEndpoint,
        httpClient: httpClient);

    // TODO(nweiz): spin up a server on localhost and redirect the user there so
    // they don't have to copy/paste the authorization code. See issue 6951.
    var authUrl = grant.getAuthorizationUrl(
        new Uri.fromString('urn:ietf:wg:oauth:2.0:oob'), scopes: _scopes);

    stdout.writeString(
        'Pub needs your authorization to upload packages on your behalf.\n'
        'Go to $authUrl\n'
        'Then click "Allow access" and paste the code below:\n'
        '> ');
    return readLine().chain(grant.handleAuthorizationCode);
  }).chain((client) {
    return _saveCredentials(cache, client.credentials).transform((_) => client);
  });
}

/// Loads the user's OAuth2 credentials from the in-memory cache or the
/// filesystem if possible. If the credentials can't be loaded for any reason,
/// the returned [Future] will complete to null.
Future<Credentials> _loadCredentials(SystemCache cache) {
  if (_credentials != null) return new Future.immediate(_credentials);
  return fileExists(_credentialsFile(cache)).chain((credentialsExist) {
    if (!credentialsExist) return new Future.immediate(null);

    return readTextFile(_credentialsFile(cache)).transform((credentialsJson) {
      var credentials = new Credentials.fromJson(credentialsJson);
      if (credentials.isExpired && !credentials.canRefresh) {
        printError("Pub's authorization to upload packages has expired and "
            "can't be automatically refreshed.");
        return null; // null means re-authorize
      }

      return credentials;
    });
  }).transformException((e) {
    printError('Warning: could not load the saved OAuth2 credentials:'
        '  $e\n'
        'Obtaining new credentials...');
    return null; // null means re-authorize
  });
}

/// Save the user's OAuth2 credentials to the in-memory cache and the
/// filesystem.
Future _saveCredentials(SystemCache cache, Credentials credentials) {
  _credentials = credentials;
  var credentialsFile = _credentialsFile(cache);
  return ensureDir(dirname(credentialsFile)).chain((_) =>
      writeTextFile(credentialsFile, credentials.toJson()));
}

/// The path to the file in which the user's OAuth2 credentials are stored.
String _credentialsFile(SystemCache cache) =>
  join(cache.rootDir, 'credentials.json');
