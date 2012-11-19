// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library authorization_code_grant_test;

import 'dart:io';
import 'dart:json';
import 'dart:uri';

import '../../unittest/lib/unittest.dart';
import '../../http/lib/http.dart' as http;
import '../../http/lib/testing.dart';
import '../lib/oauth2.dart' as oauth2;
import 'utils.dart';

final redirectUrl = new Uri.fromString('http://example.com/redirect');

ExpectClient client;

AuthorizationCodeGrant grant;

void createGrant() {
  client = new ExpectClient();
  grant = new oauth2.AuthorizationCodeGrant(
      'identifier',
      'secret',
      new Uri.fromString('https://example.com/authorization'),
      new Uri.fromString('https://example.com/token'),
      httpClient: client);
}

void main() {
  group('.getAuthorizationUrl', () {
    setUp(createGrant);

    test('builds the correct URL', () {
      expect(grant.getAuthorizationUrl(redirectUrl).toString(),
          equals('https://example.com/authorization'
              '?response_type=code'
              '&client_id=identifier'
              '&redirect_uri=http%3A%2F%2Fexample.com%2Fredirect'));
    });

    test('builds the correct URL with scopes', () {
      var authorizationUrl = grant.getAuthorizationUrl(
          redirectUrl, scopes: ['scope', 'other/scope']);
      expect(authorizationUrl.toString(),
          equals('https://example.com/authorization'
              '?response_type=code'
              '&client_id=identifier'
              '&redirect_uri=http%3A%2F%2Fexample.com%2Fredirect'
              '&scope=scope%20other%2Fscope'));
    });

    test('builds the correct URL with state', () {
      var authorizationUrl = grant.getAuthorizationUrl(
          redirectUrl, state: 'state');
      expect(authorizationUrl.toString(),
          equals('https://example.com/authorization'
              '?response_type=code'
              '&client_id=identifier'
              '&redirect_uri=http%3A%2F%2Fexample.com%2Fredirect'
              '&state=state'));
    });

    test('merges with existing query parameters', () {
      grant = new oauth2.AuthorizationCodeGrant(
          'identifier',
          'secret',
          new Uri.fromString('https://example.com/authorization?query=value'),
          new Uri.fromString('https://example.com/token'),
          httpClient: client);

      var authorizationUrl = grant.getAuthorizationUrl(redirectUrl);
      expect(authorizationUrl.toString(),
          equals('https://example.com/authorization'
              '?query=value'
              '&response_type=code'
              '&client_id=identifier'
              '&redirect_uri=http%3A%2F%2Fexample.com%2Fredirect'));
    });

    test("can't be called twice", () {
      grant.getAuthorizationUrl(redirectUrl);
      expect(() => grant.getAuthorizationUrl(redirectUrl), throwsStateError);
    });
  });

  group('.handleAuthorizationResponse', () {
    setUp(createGrant);

    test("can't be called before .getAuthorizationUrl", () {
      expect(grant.handleAuthorizationResponse({}), throwsStateError);
    });

    test("can't be called twice", () {
      grant.getAuthorizationUrl(redirectUrl);
      grant.handleAuthorizationResponse({'code': 'auth code'});
      expect(grant.handleAuthorizationResponse({'code': 'auth code'}),
          throwsStateError);
    });

    test('must have a state parameter if the authorization URL did', () {
      grant.getAuthorizationUrl(redirectUrl, state: 'state');
      expect(grant.handleAuthorizationResponse({'code': 'auth code'}),
          throwsFormatException);
    });

    test('must have the same state parameter the authorization URL did', () {
      grant.getAuthorizationUrl(redirectUrl, state: 'state');
      expect(grant.handleAuthorizationResponse({
        'code': 'auth code',
        'state': 'other state'
      }), throwsFormatException);
    });

    test('must have a code parameter', () {
      grant.getAuthorizationUrl(redirectUrl);
      expect(grant.handleAuthorizationResponse({}), throwsFormatException);
    });

    test('with an error parameter throws an AuthorizationException', () {
      grant.getAuthorizationUrl(redirectUrl);
      expect(grant.handleAuthorizationResponse({'error': 'invalid_request'}),
          throwsAuthorizationException);
    });

    test('sends an authorization code request', () {
      grant.getAuthorizationUrl(redirectUrl);
      client.expectRequest((request) {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), equals(grant.tokenEndpoint.toString()));
        expect(request.bodyFields, equals({
          'grant_type': 'authorization_code',
          'code': 'auth code',
          'redirect_uri': redirectUrl.toString(),
          'client_id': 'identifier',
          'client_secret': 'secret'
        }));

        return new Future.immediate(new http.Response(JSON.stringify({
          'access_token': 'access token',
          'token_type': 'bearer',
        }), 200, headers: {'content-type': 'application/json'}));
      });

      expect(grant.handleAuthorizationResponse({'code': 'auth code'}),
          completion(predicate((client) {
            expect(client.credentials.accessToken, equals('access token'));
            return true;
          })));
    });
  });

  group('.handleAuthorizationCode', () {
    setUp(createGrant);

    test("can't be called before .getAuthorizationUrl", () {
      expect(grant.handleAuthorizationCode('auth code'), throwsStateError);
    });

    test("can't be called twice", () {
      grant.getAuthorizationUrl(redirectUrl);
      grant.handleAuthorizationCode('auth code');
      expect(grant.handleAuthorizationCode('auth code'),
          throwsStateError);
    });

    test('sends an authorization code request', () {
      grant.getAuthorizationUrl(redirectUrl);
      client.expectRequest((request) {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), equals(grant.tokenEndpoint.toString()));
        expect(request.bodyFields, equals({
          'grant_type': 'authorization_code',
          'code': 'auth code',
          'redirect_uri': redirectUrl.toString(),
          'client_id': 'identifier',
          'client_secret': 'secret'
        }));

        return new Future.immediate(new http.Response(JSON.stringify({
          'access_token': 'access token',
          'token_type': 'bearer',
        }), 200, headers: {'content-type': 'application/json'}));
      });

      expect(grant.handleAuthorizationCode('auth code'),
          completion(predicate((client) {
            expect(client.credentials.accessToken, equals('access token'));
            return true;
          })));
    });
  });
}
