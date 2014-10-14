// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  setUp(d.validPackage.create);

  integration('upload form provides an error', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    server.handle('GET', '/api/packages/versions/new', (request) {
      return new shelf.Response.notFound(JSON.encode({
        'error': {
          'message': 'your request sucked'
        }
      }));
    });

    pub.stderr.expect('your request sucked');
    pub.shouldExit(1);
  });
}
