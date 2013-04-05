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

  integration('package validation has a warning and is canceled', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["author"] = "Nathan Weizenbaum";
    d.dir(appPath, [d.pubspec(pkg)]).create();

    var server = new ScheduledServer();
    var pub = startPublish(server);

    pub.writeLine("n");
    pub.shouldExit(0);
    expect(pub.remainingStderr(),
        completion(contains("Package upload canceled.")));
  });
}
