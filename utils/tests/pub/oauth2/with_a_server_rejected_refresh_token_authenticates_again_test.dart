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
  // Regression test for issue 8849.
  integration('with a server-rejected refresh token, authenticates again and '
      'saves credentials.json', () {
    d.validPackage.create();

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
}