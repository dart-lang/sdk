// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library oauth2_test;

import 'dart:io';
import 'dart:json' as json;
import 'dart:uri';

import '../../../pkg/http/lib/http.dart' as http;
import '../../../pkg/scheduled_test/lib/scheduled_process.dart';
import '../../../pkg/scheduled_test/lib/scheduled_test.dart';
import '../../../pkg/scheduled_test/lib/scheduled_server.dart';

import '../../pub/io.dart';
import '../../pub/utils.dart';
import 'descriptor.dart' as d;
import 'test_pub.dart';

import 'dart:async';

main() {
  setUp(() => d.validPackage.create());

  integration('with no credentials.json, authenticates and saves '
      'credentials.json', () {
    var server = new ScheduledServer();
    var pub = startPublish(server);
    confirmPublish(pub);
    authorizePub(pub, server);

    server.handle('GET', '/packages/versions/new.json', (request) {
      expect(request.headers.value('authorization'),
          equals('Bearer access token'));

      request.response.close();
    });

    // After we give pub an invalid response, it should crash. We wait for it to
    // do so rather than killing it so it'll write out the credentials file.
    pub.shouldExit(1);

    d.credentialsFile(server, 'access token').validate();
  });

  integration('with a pre-existing credentials.json does not authenticate', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);
    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request) {
      expect(request.headers.value('authorization'),
          equals('Bearer access token'));

      request.response.close();
    });

    pub.kill();
  });

  integration('with an expired credentials.json, refreshes and saves the '
      'refreshed access token to credentials.json', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token',
        refreshToken: 'refresh token',
        expiration: new DateTime.now().subtract(new Duration(hours: 1)))
        .create();

    var pub = startPublish(server);
    confirmPublish(pub);

    server.handle('POST', '/token', (request) {
      return new ByteStream(request).toBytes().then((bytes) {
        var body = new String.fromCharCodes(bytes);
        expect(body, matches(
            new RegExp(r'(^|&)refresh_token=refresh\+token(&|$)')));

        request.response.headers.contentType =
            new ContentType("application", "json");
        request.response.write(json.stringify({
          "access_token": "new access token",
          "token_type": "bearer"
        }));
        request.response.close();
      });
    });

    server.handle('GET', '/packages/versions/new.json', (request) {
      expect(request.headers.value('authorization'),
          equals('Bearer new access token'));

      request.response.close();
    });

    pub.shouldExit();

    d.credentialsFile(server, 'new access token', refreshToken: 'refresh token')
        .validate();
  });

  integration('with an expired credentials.json without a refresh token, '
       'authenticates again and saves credentials.json', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token',
        expiration: new DateTime.now().subtract(new Duration(hours: 1)))
        .create();

    var pub = startPublish(server);
    confirmPublish(pub);

    expect(pub.nextErrLine(), completion(equals("Pub's authorization to upload "
          "packages has expired and can't be automatically refreshed.")));
    authorizePub(pub, server, "new access token");

    server.handle('GET', '/packages/versions/new.json', (request) {
      expect(request.headers.value('authorization'),
          equals('Bearer new access token'));

      request.response.close();
    });

    // After we give pub an invalid response, it should crash. We wait for it to
    // do so rather than killing it so it'll write out the credentials file.
    pub.shouldExit(1);

    d.credentialsFile(server, 'new access token').validate();
  });

  integration('with a malformed credentials.json, authenticates again and '
      'saves credentials.json', () {
    var server = new ScheduledServer();
    d.dir(cachePath, [
      d.file('credentials.json', '{bad json')
    ]).create();

    var pub = startPublish(server);
    confirmPublish(pub);
    authorizePub(pub, server, "new access token");

    server.handle('GET', '/packages/versions/new.json', (request) {
      expect(request.headers.value('authorization'),
          equals('Bearer new access token'));

      request.response.close();
    });

    // After we give pub an invalid response, it should crash. We wait for it to
    // do so rather than killing it so it'll write out the credentials file.
    pub.shouldExit(1);

    d.credentialsFile(server, 'new access token').validate();
  });

  // Regression test for issue 8849.
  integration('with a server-rejected refresh token, authenticates again and '
      'saves credentials.json', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token',
        refreshToken: 'bad refresh token',
        expiration: new DateTime.now().subtract(new Duration(hours: 1)))
        .create();

    var pub = startPublish(server);
    confirmPublish(pub);

    server.handle('POST', '/token', (request) {
      return new ByteStream(request).toBytes().then((bytes) {
        var response = request.response;
        response.statusCode = 400;
        response.reasonPhrase = 'Bad request';
        response.headers.contentType = new ContentType("application", "json");
        response.write(json.stringify({"error": "invalid_request"}));
        response.close();
      });
    });

    authorizePub(pub, server, 'new access token');

    server.handle('GET', '/packages/versions/new.json', (request) {
      expect(request.headers.value('authorization'),
          equals('Bearer new access token'));

      request.response.close();
    });

    pub.kill();
  });

  integration('with server-rejected credentials, authenticates again and saves '
      'credentials.json', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request) {
      var response = request.response;
      response.statusCode = 401;
      response.headers.set('www-authenticate', 'Bearer error="invalid_token",'
          ' error_description="your token sucks"');
      response.write(json.stringify({
        'error': {'message': 'your token sucks'}
      }));
      response.close();
    });

    expect(pub.nextErrLine(), completion(equals('OAuth2 authorization failed '
        '(your token sucks).')));
    // TODO(rnystrom): The confirm line is run together with this one because
    // in normal usage, the user will have entered a newline on stdin which
    // gets echoed to the terminal. Do something better here?
    expect(pub.nextLine(), completion(equals(
        'Looks great! Are you ready to upload your package (y/n)? '
        'Pub needs your authorization to upload packages on your behalf.')));
    pub.kill();
  });
}

void authorizePub(ScheduledProcess pub, ScheduledServer server,
    [String accessToken="access token"]) {
  // TODO(rnystrom): The confirm line is run together with this one because
  // in normal usage, the user will have entered a newline on stdin which
  // gets echoed to the terminal. Do something better here?
  expect(pub.nextLine(), completion(equals(
      'Looks great! Are you ready to upload your package (y/n)? '
      'Pub needs your authorization to upload packages on your behalf.')));

  expect(pub.nextLine().then((line) {
    var match = new RegExp(r'[?&]redirect_uri=([0-9a-zA-Z%+-]+)[$&]')
        .firstMatch(line);
    expect(match, isNotNull);

    var redirectUrl = Uri.parse(decodeUriComponent(match.group(1)));
    redirectUrl = addQueryParameters(redirectUrl, {'code': 'access code'});
    return (new http.Request('GET', redirectUrl)..followRedirects = false)
      .send();
  }).then((response) {
    expect(response.headers['location'],
        equals('http://pub.dartlang.org/authorized'));
  }), completes);

  handleAccessTokenRequest(server, accessToken);
}

void handleAccessTokenRequest(ScheduledServer server, String accessToken) {
  server.handle('POST', '/token', (request) {
    return new ByteStream(request).toBytes().then((bytes) {
      var body = new String.fromCharCodes(bytes);
      expect(body, matches(new RegExp(r'(^|&)code=access\+code(&|$)')));

      request.response.headers.contentType =
          new ContentType("application", "json");
      request.response.write(json.stringify({
        "access_token": accessToken,
        "token_type": "bearer"
      }));
      request.response.close();
    });
  });
}

