// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:json' as json;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';

import '../../../pub/io.dart';
import '../../../pub/utils.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration('with an expired credentials.json, refreshes and saves the '
      'refreshed access token to credentials.json', () {
    d.validPackage.create();

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
}