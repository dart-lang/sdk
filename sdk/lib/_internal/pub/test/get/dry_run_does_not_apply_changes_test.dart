// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("--dry-run shows but does not apply changes", () {
    servePackages([
      packageMap("foo", "1.0.0")
    ]);

    d.appDir({
      "foo": "1.0.0"
    }).create();

    pubGet(args: ["--dry-run"], output: allOf([
      contains("+ foo 1.0.0"),
      contains("Would change 1 dependency.")
    ]));

    d.dir(appPath, [
      // The lockfile should not be created.
      d.nothing("pubspec.lock"),
      // The "packages" directory should not have been generated.
      d.nothing("packages")
    ]).validate();
  });
}
