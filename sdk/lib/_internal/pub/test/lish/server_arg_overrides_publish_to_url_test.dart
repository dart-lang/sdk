// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('an explicit --server argument overrides a "publishTo" url', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["publishTo"] = "http://pubspec.com";
    d.dir(appPath, [d.pubspec(pkg)]).create();

    schedulePub(args: ["lish", "--dry-run", "--server", "http://arg.com"],
        output: contains("http://arg.com"));
  });
}
