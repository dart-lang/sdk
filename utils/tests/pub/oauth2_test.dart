// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library oauth2_test;

import 'dart:io';
import 'dart:json' as json;
import 'dart:uri';

import 'test_pub.dart';
import '../../../pkg/http/lib/http.dart' as http;
import '../../../pkg/unittest/lib/unittest.dart';
import '../../pub/io.dart';
import '../../pub/utils.dart';

main() {
  setUp(() => normalPackage.scheduleCreate());

  integration('with no credentials.json, authenticates and saves '
      'credentials.json', () {
    var server = new ScheduledServer();
    var pub = startPubLish(server);
    confirmPublish(pub);
    authorizePub(pub, server);

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      expect(request.headers.value('authorization'),
          equals('Bearer access token'));

      response.outputStream.close();
    });

    pub.kill();

    credentialsFile(server, 'access token').scheduleValidate();
  });

  integration('with a pre-existing credentials.json does not authenticate', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);
    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      expect(request.headers.value('authorization'),
          equals('Bearer access token'));

      response.outputStream.close();
    });

    pub.kill();
  });

  integration('with an expired credentials.json, refreshes and saves the '
      'refreshed access token to credentials.json', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token',
        refreshToken: 'refresh token',
        expiration: new DateTime.now().subtract(new Duration(hours: 1)))
        .scheduleCreate();

    var pub = startPubLish(server);
    confirmPublish(pub);

    server.handle('POST', '/token', (request, response) {
      return consumeInputStream(request.inputStream).then((bytes) {
        var body = new String.fromCharCodes(bytes);
        expect(body, matches(
            new RegExp(r'(^|&)refresh_token=refresh\+token(&|$)')));

        response.headers.contentType = new ContentType("application", "json");
        response.outputStream.writeString(json.stringify({
          "access_token": "new access token",
          "token_type": "bearer"
        }));
        response.outputStream.close();
      });
    });

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      expect(request.headers.value('authorization'),
          equals('Bearer new access token'));

      response.outputStream.close();
    });

    pub.shouldExit();

    credentialsFile(server, 'new access token', refreshToken: 'refresh token')
        .scheduleValidate();
  });

  integration('with an expired credentials.json without a refresh token, '
       'authenticates again and saves credentials.json', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token',
        expiration: new DateTime.now().subtract(new Duration(hours: 1)))
        .scheduleCreate();

    var pub = startPubLish(server);
    confirmPublish(pub);

    expectLater(pub.nextErrLine(), equals("Pub's authorization to upload "
          "packages has expired and can't be automatically refreshed."));
    authorizePub(pub, server, "new access token");

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      expect(request.headers.value('authorization'),
          equals('Bearer new access token'));

      response.outputStream.close();
    });

    pub.kill();

    credentialsFile(server, 'new access token').scheduleValidate();
  });

  integration('with a malformed credentials.json, authenticates again and '
      'saves credentials.json', () {
    var server = new ScheduledServer();
    dir(cachePath, [
      file('credentials.json', '{bad json')
    ]).scheduleCreate();

    var pub = startPubLish(server);
    confirmPublish(pub);
    authorizePub(pub, server, "new access token");

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      expect(request.headers.value('authorization'),
          equals('Bearer new access token'));

      response.outputStream.close();
    });

    pub.kill();

    credentialsFile(server, 'new access token').scheduleValidate();
  });

  integration('with server-rejected credentials, authenticates again and saves '
      'credentials.json', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      response.statusCode = 401;
      response.headers.set('www-authenticate', 'Bearer error="invalid_token",'
          ' error_description="your token sucks"');
      response.outputStream.writeString(json.stringify({
        'error': {'message': 'your token sucks'}
      }));
      response.outputStream.close();
    });

    expectLater(pub.nextErrLine(), equals('OAuth2 authorization failed (your '
        'token sucks).'));
    // TODO(rnystrom): The confirm line is run together with this one because
    // in normal usage, the user will have entered a newline on stdin which
    // gets echoed to the terminal. Do something better here?
    expectLater(pub.nextLine(), equals(
        'Looks great! Are you ready to upload your package (y/n)? '
        'Pub needs your authorization to upload packages on your behalf.'));
    pub.kill();
  });
}

void authorizePub(ScheduledProcess pub, ScheduledServer server,
    [String accessToken="access token"]) {
  // TODO(rnystrom): The confirm line is run together with this one because
  // in normal usage, the user will have entered a newline on stdin which
  // gets echoed to the terminal. Do something better here?
  expectLater(pub.nextLine(), equals(
      'Looks great! Are you ready to upload your package (y/n)? '
      'Pub needs your authorization to upload packages on your behalf.'));

  expectLater(pub.nextLine().then((line) {
    var match = new RegExp(r'[?&]redirect_uri=([0-9a-zA-Z%+-]+)[$&]')
        .firstMatch(line);
    expect(match, isNotNull);

    var redirectUrl = Uri.parse(decodeUriComponent(match.group(1)));
    redirectUrl = addQueryParameters(redirectUrl, {'code': 'access code'});
    return (new http.Request('GET', redirectUrl)..followRedirects = false)
      .send();
  }).then((response) {
    expect(response.headers['location'],
        equals(['http://pub.dartlang.org/authorized']));
  }), anything);

  handleAccessTokenRequest(server, accessToken);
}

void handleAccessTokenRequest(ScheduledServer server, String accessToken) {
  server.handle('POST', '/token', (request, response) {
    return consumeInputStream(request.inputStream).then((bytes) {
      var body = new String.fromCharCodes(bytes);
      expect(body, matches(new RegExp(r'(^|&)code=access\+code(&|$)')));

      response.headers.contentType = new ContentType("application", "json");
      response.outputStream.writeString(json.stringify({
        "access_token": accessToken,
        "token_type": "bearer"
      }));
      response.outputStream.close();
    });
  });
}
