// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:json' as json;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';

import '../../../pub/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  setUp(d.validPackage.create);

  integration("cloud storage upload doesn't redirect", () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);

    server.handle('POST', '/upload', (request) {
      return drainStream(request).then((_) {
        // Don't set the location header.
        request.response.close();
      });
    });

    expect(pub.nextErrLine(),
        completion(equals('Failed to upload the package.')));
    pub.shouldExit(1);
  });
}
