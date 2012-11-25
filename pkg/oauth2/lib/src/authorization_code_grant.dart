// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library authorization_code_grant;

import 'dart:uri';

// TODO(nweiz): This should be a "package:" import. See issue 6745.
import '../../../http/lib/http.dart' as http;

import 'client.dart';
import 'authorization_exception.dart';
import 'handle_access_token_response.dart';
import 'utils.dart';

/// A class for obtaining credentials via an [authorization code grant][]. This
/// method of authorization involves sending the resource owner to the
/// authorization server where they will authorize the client. They're then
/// redirected back to your server, along with an authorization code. This is
/// used to obtain [Credentials] and create a fully-authorized [Client].
///
/// To use this class, you must first call [getAuthorizationUrl] to get the URL
/// to which to redirect the resource owner. Then once they've been redirected
/// back to your application, call [handleAuthorizationResponse] or
/// [handleAuthorizationCode] to process the authorization server's response and
/// construct a [Client].
///
/// [authorization code grant]: http://tools.ietf.org/html/draft-ietf-oauth-v2-31#section-4.1
class AuthorizationCodeGrant {
  /// An enum value for [_state] indicating that [getAuthorizationUrl] has not
  /// yet been called for this grant.
  static const _INITIAL_STATE = 0;

  // An enum value for [_state] indicating that [getAuthorizationUrl] has been
  // called but neither [handleAuthorizationResponse] nor
  // [handleAuthorizationCode] has been called.
  static const _AWAITING_RESPONSE_STATE = 1;

  // An enum value for [_state] indicating that [getAuthorizationUrl] and either
  // [handleAuthorizationResponse] or [handleAuthorizationCode] have been
  // called.
  static const _FINISHED_STATE = 2;

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

  /// A URL provided by the authorization server that serves as the base for the
  /// URL that the resource owner will be redirected to to authorize this
  /// client. This will usually be listed in the authorization server's
  /// OAuth2 API documentation.
  final Uri authorizationEndpoint;

  /// A URL provided by the authorization server that this library uses to
  /// obtain long-lasting credentials. This will usually be listed in the
  /// authorization server's OAuth2 API documentation.
  final Uri tokenEndpoint;

  /// The HTTP client used to make HTTP requests.
  http.Client _httpClient;

  /// The URL to which the resource owner will be redirected after they
  /// authorize this client with the authorization server.
  Uri _redirectEndpoint;

  /// The scopes that the client is requesting access to.
  List<String> _scopes;

  /// An opaque string that users of this library may specify that will be
  /// included in the response query parameters.
  String _stateString;

  /// The current state of the grant object. One of [_INITIAL_STATE],
  /// [_AWAITING_RESPONSE_STATE], or [_FINISHED_STATE].
  int _state = _INITIAL_STATE;

  /// Creates a new grant.
  ///
  /// [httpClient] is used for all HTTP requests made by this grant, as well as
  /// those of the [Client] is constructs.
  AuthorizationCodeGrant(
      this.identifier,
      this.secret,
      this.authorizationEndpoint,
      this.tokenEndpoint,
      {http.Client httpClient})
    : _httpClient = httpClient == null ? new http.Client() : httpClient;

  /// Returns the URL to which the resource owner should be redirected to
  /// authorize this client. The resource owner will then be redirected to
  /// [redirect], which should point to a server controlled by the client. This
  /// redirect will have additional query parameters that should be passed to
  /// [handleAuthorizationResponse].
  ///
  /// The specific permissions being requested from the authorization server may
  /// be specified via [scopes]. The scope strings are specific to the
  /// authorization server and may be found in its documentation. Note that you
  /// may not be granted access to every scope you request; you may check the
  /// [Credentials.scopes] field of [Client.credentials] to see which scopes you
  /// were granted.
  ///
  /// An opaque [state] string may also be passed that will be present in the
  /// query parameters provided to the redirect URL.
  ///
  /// It is a [StateError] to call this more than once.
  Uri getAuthorizationUrl(Uri redirect,
      {List<String> scopes: const <String>[], String state}) {
    if (_state != _INITIAL_STATE) {
      throw new StateError('The authorization URL has already been generated.');
    }
    _state = _AWAITING_RESPONSE_STATE;

    this._redirectEndpoint = redirect;
    this._scopes = scopes;
    this._stateString = state;
    var parameters = {
      "response_type": "code",
      "client_id": this.identifier,
      "redirect_uri": redirect.toString()
    };

    if (state != null) parameters['state'] = state;
    if (!scopes.isEmpty) parameters['scope'] = Strings.join(scopes, ' ');

    return addQueryParameters(this.authorizationEndpoint, parameters);
  }

  /// Processes the query parameters added to a redirect from the authorization
  /// server. Note that this "response" is not an HTTP response, but rather the
  /// data passed to a server controlled by the client as query parameters on
  /// the redirect URL.
  ///
  /// It is a [StateError] to call this more than once, to call it before
  /// [getAuthorizationUrl] is called, or to call it after
  /// [handleAuthorizationCode] is called.
  ///
  /// Throws [FormatError] if [parameters] is invalid according to the OAuth2
  /// spec or if the authorization server otherwise provides invalid responses.
  /// If `state` was passed to [getAuthorizationUrl], this will throw a
  /// [FormatError] if the `state` parameter doesn't match the original value.
  ///
  /// Throws [AuthorizationException] if the authorization fails.
  Future<Client> handleAuthorizationResponse(Map<String, String> parameters) {
    return async.chain((_) {
      if (_state == _INITIAL_STATE) {
        throw new StateError(
            'The authorization URL has not yet been generated.');
      } else if (_state == _FINISHED_STATE) {
        throw new StateError(
            'The authorization code has already been received.');
      }
      _state = _FINISHED_STATE;

      if (_stateString != null) {
        if (!parameters.containsKey('state')) {
          throw new FormatException('Invalid OAuth response for '
              '"$authorizationEndpoint": parameter "state" expected to be '
              '"$_stateString", was missing.');
        } else if (parameters['state'] != _stateString) {
          throw new FormatException('Invalid OAuth response for '
              '"$authorizationEndpoint": parameter "state" expected to be '
              '"$_stateString", was "${parameters['state']}".');
        }
      }

      if (parameters.containsKey('error')) {
        var description = parameters['error_description'];
        var uriString = parameters['error_uri'];
        var uri = uriString == null ? null : new Uri.fromString(uriString);
        throw new AuthorizationException(parameters['error'], description, uri);
      } else if (!parameters.containsKey('code')) {
        throw new FormatException('Invalid OAuth response for '
            '"$authorizationEndpoint": did not contain required parameter '
            '"code".');
      }

      return _handleAuthorizationCode(parameters['code']);
    });
  }

  /// Processes an authorization code directly. Usually
  /// [handleAuthorizationResponse] is preferable to this method, since it
  /// validates all of the query parameters. However, some authorization servers
  /// allow the user to copy and paste an authorization code into a command-line
  /// application, in which case this method must be used.
  ///
  /// It is a [StateError] to call this more than once, to call it before
  /// [getAuthorizationUrl] is called, or to call it after
  /// [handleAuthorizationCode] is called.
  ///
  /// Throws [FormatError] if the authorization server provides invalid
  /// responses while retrieving credentials.
  ///
  /// Throws [AuthorizationException] if the authorization fails.
  Future<Client> handleAuthorizationCode(String authorizationCode) {
    return async.chain((_) {
      if (_state == _INITIAL_STATE) {
        throw new StateError(
            'The authorization URL has not yet been generated.');
      } else if (_state == _FINISHED_STATE) {
        throw new StateError(
            'The authorization code has already been received.');
      }
      _state = _FINISHED_STATE;

      return _handleAuthorizationCode(authorizationCode);
    });
  }

  /// This works just like [handleAuthorizationCode], except it doesn't validate
  /// the state beforehand.
  Future<Client> _handleAuthorizationCode(String authorizationCode) {
    var startTime = new Date.now();
    return _httpClient.post(this.tokenEndpoint, fields: {
      "grant_type": "authorization_code",
      "code": authorizationCode,
      "redirect_uri": this._redirectEndpoint.toString(),
      // TODO(nweiz): the spec recommends that HTTP basic auth be used in
      // preference to form parameters, but Google doesn't support that. Should
      // it be configurable?
      "client_id": this.identifier,
      "client_secret": this.secret
    }).transform((response) {
      var credentials = handleAccessTokenResponse(
          response, tokenEndpoint, startTime, _scopes);
      return new Client(
          this.identifier, this.secret, credentials, httpClient: _httpClient);
    });
  }

  /// Closes the grant and frees its resources.
  ///
  /// This will close the underlying HTTP client, which is shared by the
  /// [Client] created by this grant, so it's not safe to close the grant and
  /// continue using the client.
  void close() {
    if (_httpClient != null) _httpClient.close();
    _httpClient = null;
  }
}
