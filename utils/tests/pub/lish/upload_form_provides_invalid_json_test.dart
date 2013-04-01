// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:json' as json;

import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_server.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  setUp(d.validPackage.create);

  integration('upload form provides invalid JSON', () {
    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);

    confirmPublish(pub);

    server.handle('GET', '/packages/versions/new.json', (request) {
      request.response.write('{not json');
      request.response.close();
    });

    expect(pub.nextErrLine(), completion(equals('Invalid server response:')));
    expect(pub.nextErrLine(), completion(equals('{not json')));
    pub.shouldExit(1);
  });
}
