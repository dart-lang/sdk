// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../lib/src/io.dart';
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
      return drainStream(request.read()).then((_) {
        return new shelf.Response(400,
            body: JSON.encode({"error": "invalid_request"}),
            headers: {'content-type': 'application/json'});
      });
    });

    pub.stdout.expect(startsWith('Uploading...'));
    authorizePub(pub, server, 'new access token');

    server.handle('GET', '/api/packages/versions/new', (request) {
      expect(request.headers,
          containsPair('authorization', 'Bearer new access token'));

      return new shelf.Response(200);
    });

    pub.kill();
  });
}