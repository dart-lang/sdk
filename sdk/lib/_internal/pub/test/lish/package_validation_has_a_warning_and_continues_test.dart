// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:scheduled_test/scheduled_server.dart';
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import 'package:shelf/shelf.dart' as shelf;

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  setUp(d.validPackage.create);

  integration('package validation has a warning and continues', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["author"] = "Natalie Weizenbaum";
    d.dir(appPath, [d.pubspec(pkg)]).create();

    var server = new ScheduledServer();
    d.credentialsFile(server, 'access token').create();
    var pub = startPublish(server);
    pub.writeLine("y");
    handleUploadForm(server);
    handleUpload(server);

    server.handle('GET', '/create', (request) {
      return new shelf.Response.ok(JSON.encode({
        'success': {'message': 'Package test_pkg 1.0.0 uploaded!'}
      }));
    });

    pub.shouldExit(exit_codes.SUCCESS);
    pub.stdout.expect(consumeThrough('Package test_pkg 1.0.0 uploaded!'));
  });
}
