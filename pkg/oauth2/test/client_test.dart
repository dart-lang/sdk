// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library client_test;

import 'dart:io';
import 'dart:json';
import 'dart:uri';

import '../../unittest/lib/unittest.dart';
import '../../http/lib/http.dart' as http;
import '../lib/oauth2.dart' as oauth2;
import 'utils.dart';

final Uri requestUri = new Uri.fromString("http://example.com/resource");

final Uri tokenEndpoint = new Uri.fromString('http://example.com/token');

ExpectClient httpClient;

void createHttpClient() {
  httpClient = new ExpectClient();
}

void main() {
  group('with expired credentials', () {
    setUp(createHttpClient);

    test("that can't be refreshed throws an ExpirationException on send", () {
      var expiration = new Date.now().subtract(new Duration(hours: 1));
      var credentials = new oauth2.Credentials(
          'access token', null, null, [], expiration);
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      expect(client.get(requestUri), throwsExpirationException);
    });

    test("that can be refreshed refreshes the credentials and sends the "
        "request", () {
      var expiration = new Date.now().subtract(new Duration(hours: 1));
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

      expect(client.read(requestUri).transform((_) {
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

      expect(client.refreshCredentials().transform((_) {
        expect(client.credentials.accessToken, equals('new access token'));
      }), completes);
    });

    test("without a refresh token can't manually refresh the credentials", () {
      var credentials = new oauth2.Credentials('access token');
      var client = new oauth2.Client('identifier', 'secret', credentials,
          httpClient: httpClient);

      expect(client.refreshCredentials(), throwsStateError);
    });
  });
}
