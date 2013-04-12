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
  integration('with an expired credentials.json without a refresh token, '
       'authenticates again and saves credentials.json', () {
    d.validPackage.create();

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
}
