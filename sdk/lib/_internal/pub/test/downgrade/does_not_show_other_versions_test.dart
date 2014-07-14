// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("does not show how many other versions are available", () {
    servePackages([
      packageMap("downgraded", "1.0.0"),
      packageMap("downgraded", "2.0.0"),
      packageMap("downgraded", "3.0.0-dev")
    ]);

    d.appDir({
      "downgraded": "3.0.0-dev"
    }).create();

    pubGet();

    // Loosen the constraints.
    d.appDir({
      "downgraded": ">=2.0.0"
    }).create();

    pubDowngrade(output: contains("downgraded 2.0.0 (was 3.0.0-dev)"));
  });
}
