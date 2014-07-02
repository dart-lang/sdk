// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("shows how many newer versions are available", () {
    servePackages([
      packageMap("multiple_newer", "1.0.0"),
      packageMap("multiple_newer", "1.0.1-unstable.1"),
      packageMap("multiple_newer", "1.0.1"),
      packageMap("multiple_newer", "1.0.2-unstable.1"),
      packageMap("multiple_newer_stable", "1.0.0"),
      packageMap("multiple_newer_stable", "1.0.1"),
      packageMap("multiple_newer_stable", "1.0.2"),
      packageMap("multiple_newer_unstable", "1.0.0"),
      packageMap("multiple_newer_unstable", "1.0.1-unstable.1"),
      packageMap("multiple_newer_unstable", "1.0.1-unstable.2"),
      packageMap("no_newer", "1.0.0"),
      packageMap("one_newer_unstable", "1.0.0"),
      packageMap("one_newer_unstable", "1.0.1-unstable.1"),
      packageMap("one_newer_stable", "1.0.0"),
      packageMap("one_newer_stable", "1.0.1")
    ]);

    // Constraint everything to the first version.
    d.appDir({
      "multiple_newer": "1.0.0",
      "multiple_newer_stable": "1.0.0",
      "multiple_newer_unstable": "1.0.0",
      "no_newer": "1.0.0",
      "one_newer_unstable": "1.0.0",
      "one_newer_stable": "1.0.0"
    }).create();

    // Upgrade everything.
    pubUpgrade(output: new RegExp(r"""
Resolving dependencies\.\.\..*
. multiple_newer 1\.0\.0 \(1\.0\.1 available\)
. multiple_newer_stable 1\.0\.0 \(1\.0\.2\ available\)
. multiple_newer_unstable 1\.0\.0 \(1\.0\.1-unstable\.2 available\)
. no_newer 1\.0\.0
. one_newer_stable 1\.0\.0 \(1\.0\.1 available\)
. one_newer_unstable 1\.0\.0 \(1\.0\.1-unstable\.1 available\)
""", multiLine: true));
  });
}
