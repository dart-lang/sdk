// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration(
      'with no credentials.json, authenticates and saves ' 'credentials.json',
      () {
    d.validPackage.create();

    var server = new ScheduledServer();
    var pub = startPublish(server);
    confirmPublish(pub);
    authorizePub(pub, server);

    server.handle('GET', '/api/packages/versions/new', (request) {
      expect(
          request.headers,
          containsPair('authorization', 'Bearer access token'));

      return new shelf.Response(200);
    });

    // After we give pub an invalid response, it should crash. We wait for it to
    // do so rather than killing it so it'll write out the credentials file.
    pub.shouldExit(1);

    d.credentialsFile(server, 'access token').validate();
  });
}
