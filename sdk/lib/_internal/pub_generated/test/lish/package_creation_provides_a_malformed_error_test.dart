// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  setUp(d.validPackage.create);

  integration('package creation provides a malformed error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);
    handleUploadForm(server);
    handleUpload(server);

    var body = {
      'error': 'Your package was too boring.'
    };
    server.handle('GET', '/create', (request) {
      return new shelf.Response.notFound(JSON.encode(body));
    });

    pub.stderr.expect('Invalid server response:');
    pub.stderr.expect(JSON.encode(body));
    pub.shouldExit(1);
  });
}
