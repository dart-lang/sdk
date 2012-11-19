// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library client;

import 'dart:uri';

import '../../../http/lib/http.dart' as http;

import 'credentials.dart';
import 'expiration_exception.dart';
import 'utils.dart';

// TODO(nweiz): Add an onCredentialsRefreshed event once we have some event
// infrastructure.
/// An OAuth2 client. This acts as a drop-in replacement for an
/// [http.BaseClient], while sending OAuth2 authorization credentials along with
/// each request.
///
/// The client also automatically refreshes its credentials if possible. When it
/// makes a request, if its credentials are expired, it will first refresh them.
/// This means that any request may throw an [AuthorizationException] if the
/// refresh is not authorized for some reason, a [FormatException] if the
/// authorization server provides ill-formatted responses, or an
/// [ExpirationException] if the credentials are expired and can't be refreshed.
///
/// Currently this client doesn't attempt to identify errors from the resource
/// server that are caused by authentication failure. However, it may throw
/// [AuthorizationException]s for such errors in the future.
///
/// If you already have a set of [Credentials], you can construct a [Client]
/// directly. However, in order to first obtain the credentials, you must
/// authorize. At the time of writing, the only authorization method this
/// library supports is [AuthorizationCodeGrant].
class Client extends http.BaseClient {
  /// The client identifier for this client. The authorization server will issue
  /// each client a separate client identifier and secret, which allows the
  /// server to tell which client is accessing it. Some servers may also have an
  /// anonymous identifier/secret pair that any client may use.
  ///
  /// This is usually global to the program using this library.
  final String identifier;

  /// The client secret for this client. The authorization server will issue
  /// each client a separate client identifier and secret, which allows the
  /// server to tell which client is accessing it. Some servers may also have an
  /// anonymous identifier/secret pair that any client may use.
  ///
  /// This is usually global to the program using this library.
  ///
  /// Note that clients whose source code or binary executable is readily
  /// available may not be able to make sure the client secret is kept a secret.
  /// This is fine; OAuth2 servers generally won't rely on knowing with
  /// certainty that a client is who it claims to be.
  final String secret;

  /// The credentials this client uses to prove to the resource server that it's
  /// authorized. This may change from request to request as the credentials
  /// expire and the client refreshes them automatically.
  Credentials get credentials => _credentials;
  Credentials _credentials;

  /// The underlying HTTP client.
  http.BaseClient _httpClient;

  /// Creates a new client from a pre-existing set of credentials. When
  /// authorizing a client for the first time, you should use
  /// [AuthorizationCodeGrant] instead of constructing a [Client] directly.
  ///
  /// [httpClient] is the underlying client that this forwards requests to after
  /// adding authorization credentials to them.
  Client(
      this.identifier,
      this.secret,
      this._credentials,
      {http.BaseClient httpClient})
    : _httpClient = httpClient == null ? new http.Client() : httpClient;

  /// Sends an HTTP request with OAuth2 authorization credentials attached. This
  /// will also automatically refresh this client's [Credentials] before sending
  /// the request if necessary.
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return async.chain((_) {
      if (!credentials.isExpired) return new Future.immediate(null);
      if (!credentials.canRefresh) throw new ExpirationException(credentials);
      return refreshCredentials();
    }).chain((_) {
      request.headers['authorization'] = "Bearer ${credentials.accessToken}";
      return _httpClient.send(request);
    });
    // TODO(nweiz): parse 401 errors that are caused by OAuth errors here.
  }

  /// Explicitly refreshes this client's credentials. Returns this client.
  ///
  /// This will throw a [StateError] if the [Credentials] can't be refreshed, an
  /// [AuthorizationException] if refreshing the credentials fails, or a
  /// [FormatError] if the authorization server returns invalid responses.
  ///
  /// You may request different scopes than the default by passing in
  /// [newScopes]. These must be a subset of the scopes in the
  /// [Credentials.scopes] field of [Client.credentials].
  Future<Client> refreshCredentials([List<String> newScopes]) {
    return async.chain((_) {
      if (!credentials.canRefresh) {
        var prefix = "OAuth credentials";
        if (credentials.isExpired) prefix = "$prefix have expired and";
        throw new StateError("$prefix can't be refreshed.");
      }

      return credentials.refresh(identifier, secret,
          newScopes: newScopes, httpClient: _httpClient);
    }).transform((credentials) {
      _credentials = credentials;
      return this;
    });
  }

  /// Closes this client and its underlying HTTP client.
  void close() {
    if (_httpClient != null) _httpClient.close();
    _httpClient = null;
  }
}
