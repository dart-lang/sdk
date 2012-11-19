// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library credentials;

import 'dart:json';
import 'dart:uri';

import '../../../http/lib/http.dart' as http;
import 'handle_access_token_response.dart';
import 'utils.dart';

/// Credentials that prove that a client is allowed to access a resource on the
/// resource owner's behalf. These credentials are long-lasting and can be
/// safely persisted across multiple runs of the program.
///
/// Many authorization servers will attach an expiration date to a set of
/// credentials, along with a token that can be used to refresh the credentials
/// once they've expired. The [Client] will automatically refresh its
/// credentials when necessary. It's also possible to explicitly refresh them
/// via [Client.refreshCredentials] or [Credentials.refresh].
///
/// Note that a given set of credentials can only be refreshed once, so be sure
/// to save the refreshed credentials for future use.
class Credentials {
  /// The token that is sent to the resource server to prove the authorization
  /// of a client.
  final String accessToken;

  /// The token that is sent to the authorization server to refresh the
  /// credentials. This is optional.
  final String refreshToken;

  /// The URL of the authorization server endpoint that's used to refresh the
  /// credentials. This is optional.
  final Uri tokenEndpoint;

  /// The specific permissions being requested from the authorization server.
  /// The scope strings are specific to the authorization server and may be
  /// found in its documentation.
  final List<String> scopes;

  /// The date at which these credentials will expire. This is likely to be a
  /// few seconds earlier than the server's idea of the expiration date.
  final Date expiration;

  /// Whether or not these credentials have expired. Note that it's possible the
  /// credentials will expire shortly after this is called. However, since the
  /// client's expiration date is kept a few seconds earlier than the server's,
  /// there should be enough leeway to rely on this.
  bool get isExpired => expiration != null && new Date.now() > expiration;

  /// Whether it's possible to refresh these credentials.
  bool get canRefresh => refreshToken != null && tokenEndpoint != null;

  /// Creates a new set of credentials.
  ///
  /// This class is usually not constructed directly; rather, it's accessed via
  /// [Client.credentials] after a [Client] is created by
  /// [AuthorizationCodeGrant]. Alternately, it may be loaded from a serialized
  /// form via [Credentials.fromJson].
  Credentials(
      this.accessToken,
      [this.refreshToken,
       this.tokenEndpoint,
       this.scopes,
       this.expiration]);

  /// Loads a set of credentials from a JSON-serialized form. Throws
  /// [FormatException] if the JSON is incorrectly formatted.
  factory Credentials.fromJson(String json) {
    void validate(bool condition, String message) {
      if (condition) return;
      throw new FormatException(
          "Failed to load credentials: $message.\n\n$json");
    }

    var parsed;
    try {
      parsed = JSON.parse(json);
    } catch (e) {
      // TODO(nweiz): narrow this catch clause once issue 6775 is fixed.
      validate(false, 'invalid JSON');
    }

    validate(parsed is Map, 'was not a JSON map');
    validate(parsed.containsKey('accessToken'),
        'did not contain required field "accessToken"');
    validate(parsed['accessToken'] is String,
        'required field "accessToken" was not a string, was '
        '${parsed["accessToken"]}');


    for (var stringField in ['refreshToken', 'tokenEndpoint']) {
      var value = parsed[stringField];
      validate(value == null || value is String,
          'field "$stringField" was not a string, was "$value"');
    }

    var scopes = parsed['scopes'];
    validate(scopes == null || scopes is List,
        'field "scopes" was not a list, was "$scopes"');

    var tokenEndpoint = parsed['tokenEndpoint'];
    if (tokenEndpoint != null) {
      tokenEndpoint = new Uri.fromString(tokenEndpoint);
    }
    var expiration = parsed['expiration'];
    if (expiration != null) {
      validate(expiration is int,
          'field "expiration" was not an int, was "$expiration"');
      expiration = new Date.fromMillisecondsSinceEpoch(expiration);
    }

    return new Credentials(
        parsed['accessToken'],
        parsed['refreshToken'],
        tokenEndpoint,
        scopes,
        expiration);
  }

  /// Serializes a set of credentials to JSON. Nothing is guaranteed about the
  /// output except that it's valid JSON and compatible with
  /// [Credentials.toJson].
  String toJson() => JSON.stringify({
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'tokenEndpoint': tokenEndpoint == null ? null : tokenEndpoint.toString(),
    'scopes': scopes,
    'expiration': expiration == null ? null : expiration.millisecondsSinceEpoch
  });

  /// Returns a new set of refreshed credentials. See [Client.identifier] and
  /// [Client.secret] for explanations of those parameters.
  ///
  /// You may request different scopes than the default by passing in
  /// [newScopes]. These must be a subset of [scopes].
  ///
  /// This will throw a [StateError] if these credentials can't be refreshed, an
  /// [AuthorizationException] if refreshing the credentials fails, or a
  /// [FormatError] if the authorization server returns invalid responses.
  Future<Credentials> refresh(
      String identifier,
      String secret,
      {List<String> newScopes,
       http.BaseClient httpClient}) {
    var scopes = this.scopes;
    if (newScopes != null) scopes = newScopes;
    if (scopes == null) scopes = <String>[];
    if (httpClient == null) httpClient = new http.Client();

    var startTime = new Date.now();
    return async.chain((_) {
      if (refreshToken == null) {
        throw new StateError("Can't refresh credentials without a refresh "
            "token.");
      } else if (tokenEndpoint == null) {
        throw new StateError("Can't refresh credentials without a token "
            "endpoint.");
      }

      var fields = {
        "grant_type": "refresh_token",
        "refresh_token": refreshToken,
        // TODO(nweiz): the spec recommends that HTTP basic auth be used in
        // preference to form parameters, but Google doesn't support that.
        // Should it be configurable?
        "client_id": identifier,
        "client_secret": secret
      };
      if (!scopes.isEmpty) fields["scope"] = Strings.join(scopes, ' ');

      return httpClient.post(tokenEndpoint, fields: fields);
    }).transform((response) {
      return handleAccessTokenResponse(
          response, tokenEndpoint, startTime, scopes);
    }).transform((credentials) {
      // The authorization server may issue a new refresh token. If it doesn't,
      // we should re-use the one we already have.
      if (credentials.refreshToken != null) return credentials;
      return new Credentials(
          credentials.accessToken,
          this.refreshToken,
          credentials.tokenEndpoint,
          credentials.scopes,
          credentials.expiration);
    });
  }
}
