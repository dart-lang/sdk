// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library client_test;

import 'dart:async';
import 'dart:io';
import 'dart:json' as JSON;
import 'dart:uri';

import '../../unittest/lib/unittest.dart';
import '../../http/lib/http.dart' as http;
import '../lib/oauth2.dart' as oauth2;
import 'utils.dart';

final Uri requestUri = Uri.parse("http://example.com/resource");

final Uri tokenEndpoint = Uri.parse('http://example.com/token');

ExpectClient httpClient;

void createHttpClient() {
  httpClient = new ExpectClient();
}

void expectFutureThrows(future, predicate) {
  future.catchError(expectAsync1((AsyncError e) {
    expect(predicate(e.error), isTrue);
  }));
}

void main() {
  group('with expired credentials', () {
    setUp(createHttpClient);

    test("that can't be refreshed throws an ExpirationException on send", () {
      var expiration = new DateTime.now().subtract(new Duration(hours: 1));
      var credentials = new oauth2.Credentials(
          'access token', null, null, [], expiration);
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      expectFutureThrows(client.get(requestUri),
                         (e) => e is oauth2.ExpirationException);
    });

    test("that can be refreshed refreshes the credentials and sends the "
        "request", () {
      var expiration = new DateTime.now().subtract(new Duration(hours: 1));
      var credentials = new oauth2.Credentials(
          'access token', 'refresh token', tokenEndpoint, [], expiration);
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      httpClient.expectRequest((request) {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), equals(tokenEndpoint.toString()));
        return new Future.immediate(new http.Response(JSON.stringify({
          'access_token': 'new access token',
          'token_type': 'bearer'
        }), 200, headers: {'content-type': 'application/json'}));
      });

      httpClient.expectRequest((request) {
        expect(request.method, equals('GET'));
        expect(request.url.toString(), equals(requestUri.toString()));
        expect(request.headers['authorization'],
            equals('Bearer new access token'));

        return new Future.immediate(new http.Response('good job', 200));
      });

      expect(client.read(requestUri).then((_) {
        expect(client.credentials.accessToken, equals('new access token'));
      }), completes);
    });
  });

  group('with valid credentials', () {
    setUp(createHttpClient);

    test("sends a request with bearer authorization", () {
      var credentials = new oauth2.Credentials('access token');
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      httpClient.expectRequest((request) {
        expect(request.method, equals('GET'));
        expect(request.url.toString(), equals(requestUri.toString()));
        expect(request.headers['authorization'],
            equals('Bearer access token'));

        return new Future.immediate(new http.Response('good job', 200));
      });

      expect(client.read(requestUri), completion(equals('good job')));
    });

    test("can manually refresh the credentials", () {
      var credentials = new oauth2.Credentials(
          'access token', 'refresh token', tokenEndpoint);
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      httpClient.expectRequest((request) {
        expect(request.method, equals('POST'));
        expect(request.url.toString(), equals(tokenEndpoint.toString()));
        return new Future.immediate(new http.Response(JSON.stringify({
          'access_token': 'new access token',
          'token_type': 'bearer'
        }), 200, headers: {'content-type': 'application/json'}));
      });

      expect(client.refreshCredentials().then((_) {
        expect(client.credentials.accessToken, equals('new access token'));
      }), completes);
    });

    test("without a refresh token can't manually refresh the credentials", () {
      var credentials = new oauth2.Credentials('access token');
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      expectFutureThrows(client.refreshCredentials(),
                         (e) => e is StateError);
    });
  });

  group('with invalid credentials', () {
    setUp(createHttpClient);

    test('throws an AuthorizationException for a 401 response', () {
      var credentials = new oauth2.Credentials('access token');
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      httpClient.expectRequest((request) {
        expect(request.method, equals('GET'));
        expect(request.url.toString(), equals(requestUri.toString()));
        expect(request.headers['authorization'],
            equals('Bearer access token'));

        var authenticate = 'Bearer error="invalid_token", error_description='
            '"Something is terribly wrong."';
        return new Future.immediate(new http.Response('bad job', 401,
                headers: {'www-authenticate': authenticate}));
      });

      expectFutureThrows(client.read(requestUri),
                         (e) => e is oauth2.AuthorizationException);
    });

    test('passes through a 401 response without www-authenticate', () {
      var credentials = new oauth2.Credentials('access token');
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      httpClient.expectRequest((request) {
        expect(request.method, equals('GET'));
        expect(request.url.toString(), equals(requestUri.toString()));
        expect(request.headers['authorization'],
            equals('Bearer access token'));

        return new Future.immediate(new http.Response('bad job', 401));
      });

      expect(
          client.get(requestUri).then((response) => response.statusCode),
          completion(equals(401)));
    });

    test('passes through a 401 response with invalid www-authenticate', () {
      var credentials = new oauth2.Credentials('access token');
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      httpClient.expectRequest((request) {
        expect(request.method, equals('GET'));
        expect(request.url.toString(), equals(requestUri.toString()));
        expect(request.headers['authorization'],
            equals('Bearer access token'));

        var authenticate = 'Bearer error="invalid_token", error_description='
          '"Something is terribly wrong.", ';
        return new Future.immediate(new http.Response('bad job', 401,
                headers: {'www-authenticate': authenticate}));
      });

      expect(
          client.get(requestUri).then((response) => response.statusCode),
          completion(equals(401)));
    });

    test('passes through a 401 response with non-bearer www-authenticate', () {
      var credentials = new oauth2.Credentials('access token');
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      httpClient.expectRequest((request) {
        expect(request.method, equals('GET'));
        expect(request.url.toString(), equals(requestUri.toString()));
        expect(request.headers['authorization'],
            equals('Bearer access token'));

        return new Future.immediate(new http.Response('bad job', 401,
                headers: {'www-authenticate': 'Digest'}));
      });

      expect(
          client.get(requestUri).then((response) => response.statusCode),
          completion(equals(401)));
    });

    test('passes through a 401 response with non-OAuth2 www-authenticate', () {
      var credentials = new oauth2.Credentials('access token');
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      httpClient.expectRequest((request) {
        expect(request.method, equals('GET'));
        expect(request.url.toString(), equals(requestUri.toString()));
        expect(request.headers['authorization'],
            equals('Bearer access token'));

        return new Future.immediate(new http.Response('bad job', 401,
                headers: {'www-authenticate': 'Bearer'}));
      });

      expect(
          client.get(requestUri).then((response) => response.statusCode),
          completion(equals(401)));
    });
  });
}
