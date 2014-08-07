// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('does not publish if the package is private even if a server '
      'argument is provided', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["publishTo"] = "none";
    d.dir(appPath, [d.pubspec(pkg)]).create();

    schedulePub(args: ["lish", "--server", "http://example.com"],
        error: startsWith("A private package cannot be published."),
        exitCode: exit_codes.DATA);
  });
}
