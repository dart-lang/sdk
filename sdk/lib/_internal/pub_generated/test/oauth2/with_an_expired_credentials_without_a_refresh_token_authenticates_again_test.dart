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
      'with an expired credentials.json without a refresh token, '
          'authenticates again and saves credentials.json',
      () {
    d.validPackage.create();

    var server = new ScheduledServer();
    d.credentialsFile(
        server,
        'access token',
        expiration: new DateTime.now().subtract(new Duration(hours: 1))).create();

    var pub = startPublish(server);
    confirmPublish(pub);

    pub.stderr.expect(
        "Pub's authorization to upload packages has expired and "
            "can't be automatically refreshed.");
    authorizePub(pub, server, "new access token");

    server.handle('GET', '/api/packages/versions/new', (request) {
      expect(
          request.headers,
          containsPair('authorization', 'Bearer new access token'));

      return new shelf.Response(200);
    });

    // After we give pub an invalid response, it should crash. We wait for it to
    // do so rather than killing it so it'll write out the credentials file.
    pub.shouldExit(1);

    d.credentialsFile(server, 'new access token').validate();
  });
}
