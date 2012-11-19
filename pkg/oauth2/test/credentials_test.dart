// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library credentials_test;

import 'dart:io';
import 'dart:json';
import 'dart:uri';

import '../../unittest/lib/unittest.dart';
import '../../http/lib/http.dart' as http;
import '../lib/oauth2.dart' as oauth2;
import 'utils.dart';

final Uri tokenEndpoint = new Uri.fromString('http://example.com/token');

ExpectClient httpClient;

void main() {
  setUp(() => httpClient = new ExpectClient());

  test('is not expired if no expiration exists', () {
    var credentials = new oauth2.Credentials('access token');
    expect(credentials.isExpired, isFalse);
  });

  test('is not expired if the expiration is in the future', () {
    var expiration = new Date.now().add(new Duration(hours: 1));
    var credentials = new oauth2.Credentials(
        'access token', null, null, null, expiration);
    expect(credentials.isExpired, isFalse);
  });

  test('is expired if the expiration is in the past', () {
    var expiration = new Date.now().subtract(new Duration(hours: 1));
    var credentials = new oauth2.Credentials(
        'access token', null, null, null, expiration);
    expect(credentials.isExpired, isTrue);
  });

  test("can't refresh without a refresh token", () {
    var credentials = new oauth2.Credentials(
        'access token', null, tokenEndpoint);
    expect(credentials.canRefresh, false);
    expect(credentials.refresh('identifier', 'secret', httpClient: httpClient),
        throwsStateError);
  });

  test("can't refresh without a token endpoint", () {
    var credentials = new oauth2.Credentials('access token', 'refresh token');
    expect(credentials.canRefresh, false);
    expect(credentials.refresh('identifier', 'secret', httpClient: httpClient),
        throwsStateError);
  });

  test("can refresh with a refresh token and a token endpoint", () {
    var credentials = new oauth2.Credentials(
        'access token', 'refresh token', tokenEndpoint, ['scope1', 'scope2']);
    expect(credentials.canRefresh, true);

    httpClient.expectRequest((request) {
      expect(request.method, equals('POST'));
      expect(request.url.toString(), equals(tokenEndpoint.toString()));
      expect(request.bodyFields, equals({
        "grant_type": "refresh_token",
        "refresh_token": "refresh token",
        "scope": "scope1 scope2",
        "client_id": "identifier",
        "client_secret": "secret"
      }));

      return new Future.immediate(new http.Response(JSON.stringify({
        'access_token': 'new access token',
        'token_type': 'bearer',
        'refresh_token': 'new refresh token'
      }), 200, headers: {'content-type': 'application/json'}));
    });

    
    expect(credentials.refresh('identifier', 'secret', httpClient: httpClient)
        .transform((credentials) {
      expect(credentials.accessToken, equals('new access token'));
      expect(credentials.refreshToken, equals('new refresh token'));
    }), completes);
  });

  test("uses the old refresh token if a new one isn't provided", () {
    var credentials = new oauth2.Credentials(
        'access token', 'refresh token', tokenEndpoint);
    expect(credentials.canRefresh, true);

    httpClient.expectRequest((request) {
      expect(request.method, equals('POST'));
      expect(request.url.toString(), equals(tokenEndpoint.toString()));
      expect(request.bodyFields, equals({
        "grant_type": "refresh_token",
        "refresh_token": "refresh token",
        "client_id": "identifier",
        "client_secret": "secret"
      }));

      return new Future.immediate(new http.Response(JSON.stringify({
        'access_token': 'new access token',
        'token_type': 'bearer'
      }), 200, headers: {'content-type': 'application/json'}));
    });

    
    expect(credentials.refresh('identifier', 'secret', httpClient: httpClient)
        .transform((credentials) {
      expect(credentials.accessToken, equals('new access token'));
      expect(credentials.refreshToken, equals('refresh token'));
    }), completes);
  });

  group("fromJson", () {
    oauth2.Credentials fromMap(Map map) =>
      new oauth2.Credentials.fromJson(JSON.stringify(map));

    test("should load the same credentials from toJson", () {
      var expiration = new Date.now().subtract(new Duration(hours: 1));
      var credentials = new oauth2.Credentials(
          'access token', 'refresh token', tokenEndpoint, ['scope1', 'scope2'],
          expiration);
      var reloaded = new oauth2.Credentials.fromJson(credentials.toJson());

      expect(reloaded.accessToken, equals(credentials.accessToken));
      expect(reloaded.refreshToken, equals(credentials.refreshToken));
      expect(reloaded.tokenEndpoint.toString(),
          equals(credentials.tokenEndpoint.toString()));
      expect(reloaded.scopes, equals(credentials.scopes));
      expect(reloaded.expiration, equals(credentials.expiration));
    });

    test("should throw a FormatException for invalid JSON", () {
      expect(() => new oauth2.Credentials.fromJson("foo bar"),
          throwsFormatException);
    });

    test("should throw a FormatException for JSON that's not a map", () {
      expect(() => new oauth2.Credentials.fromJson("null"),
          throwsFormatException);
    });

    test("should throw a FormatException if there is no accessToken", () {
      expect(() => fromMap({}), throwsFormatException);
    });

    test("should throw a FormatException if accessToken is not a string", () {
      expect(() => fromMap({"accessToken": 12}), throwsFormatException);
    });

    test("should throw a FormatException if refreshToken is not a string", () {
      expect(() => fromMap({"accessToken": "foo", "refreshToken": 12}),
          throwsFormatException);
    });

    test("should throw a FormatException if tokenEndpoint is not a string", () {
      expect(() => fromMap({"accessToken": "foo", "tokenEndpoint": 12}),
          throwsFormatException);
    });

    test("should throw a FormatException if scopes is not a list", () {
      expect(() => fromMap({"accessToken": "foo", "scopes": 12}),
          throwsFormatException);
    });

    test("should throw a FormatException if expiration is not an int", () {
      expect(() => fromMap({"accessToken": "foo", "expiration": "12"}),
          throwsFormatException);
    });
  });
}
