// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library oauth2_test;

import 'dart:io';
import 'dart:json';

import 'test_pub.dart';
import '../../../pkg/unittest/lib/unittest.dart';
import '../../pub/io.dart';

main() {
  setUp(() => dir(appPath, [libPubspec("test_pkg", "1.0.0")]).scheduleCreate());

  test('with no credentials.json, authenticates and saves credentials.json',
      () {
    var server = new ScheduledServer();
    var pub = startPubLish(server);

    expectLater(pub.nextLine(), equals('Pub needs your '
       'authorization to upload packages on your behalf.'));
    pub.writeLine('access code');

    handleAccessTokenRequest(server, "access token");

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      expect(request.headers.value('authorization'),
          equals('Bearer access token'));

      response.outputStream.close();
    });

    pub.kill();

    credentialsFile(server, 'access token').scheduleValidate();

    run();
  });

  test('with a pre-existing credentials.json does not authenticate', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token').scheduleCreate();
    var pub = startPubLish(server);

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      expect(request.headers.value('authorization'),
          equals('Bearer access token'));

      response.outputStream.close();
    });

    pub.kill();

    run();
  });

  test('with an expired credentials.json, refreshes and saves the refreshed '
      'access token to credentials.json', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token',
        refreshToken: 'refresh token',
        expiration: new Date.now().subtract(new Duration(hours: 1)))
        .scheduleCreate();

    var pub = startPubLish(server);

    server.handle('POST', '/token', (request, response) {
      return consumeInputStream(request.inputStream).transform((bytes) {
        var body = new String.fromCharCodes(bytes);
        expect(body, matches(
            new RegExp(r'(^|&)refresh_token=refresh%20token(&|$)')));

        response.headers.contentType = new ContentType("application", "json");
        response.outputStream.writeString(JSON.stringify({
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

    run();
  });

  test('with an expired credentials.json without a refresh token, '
       'authenticates again and saves credentials.json', () {
    var server = new ScheduledServer();
    credentialsFile(server, 'access token',
        expiration: new Date.now().subtract(new Duration(hours: 1)))
        .scheduleCreate();

    var pub = startPubLish(server);

    expectLater(pub.nextErrLine(), equals("Pub's authorization to upload "
          "packages has expired and can't be automatically refreshed."));
    expectLater(pub.nextLine(), equals('Pub needs your '
       'authorization to upload packages on your behalf.'));
    pub.writeLine('access code');

    handleAccessTokenRequest(server, "new access token");

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      expect(request.headers.value('authorization'),
          equals('Bearer new access token'));

      response.outputStream.close();
    });

    pub.kill();

    credentialsFile(server, 'new access token').scheduleValidate();

    run();
  });

  test('with a malformed credentials.json, authenticates again and saves '
      'credentials.json', () {
    var server = new ScheduledServer();
    dir(cachePath, [
      file('credentials.json', '{bad json')
    ]).scheduleCreate();

    var pub = startPubLish(server);

    expectLater(pub.nextLine(), equals('Pub needs your '
       'authorization to upload packages on your behalf.'));
    pub.writeLine('access code');

    handleAccessTokenRequest(server, "new access token");

    server.handle('GET', '/packages/versions/new.json', (request, response) {
      expect(request.headers.value('authorization'),
          equals('Bearer new access token'));

      response.outputStream.close();
    });

    pub.kill();

    credentialsFile(server, 'new access token').scheduleValidate();

    run();
  });
}

void handleAccessTokenRequest(ScheduledServer server, String accessToken) {
  server.handle('POST', '/token', (request, response) {
    return consumeInputStream(request.inputStream).transform((bytes) {
      var body = new String.fromCharCodes(bytes);
      expect(body, matches(new RegExp(r'(^|&)code=access%20code(&|$)')));

      response.headers.contentType = new ContentType("application", "json");
      response.outputStream.writeString(JSON.stringify({
        "access_token": accessToken,
        "token_type": "bearer"
      }));
      response.outputStream.close();
    });
  });
}
