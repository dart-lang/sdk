// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("does not show how many newer versions are available for "
      "packages that are locked and not being upgraded", () {
    servePackages([
      packageMap("not_upgraded", "1.0.0"),
      packageMap("not_upgraded", "2.0.0"),
      packageMap("not_upgraded", "3.0.0-dev"),
      packageMap("upgraded", "1.0.0"),
      packageMap("upgraded", "2.0.0"),
      packageMap("upgraded", "3.0.0-dev")
    ]);

    // Constraint everything to the first version.
    d.appDir({
      "not_upgraded": "1.0.0",
      "upgraded": "1.0.0"
    }).create();

    pubGet();

    // Loosen the constraints.
    d.appDir({
      "not_upgraded": "any",
      "upgraded": "any"
    }).create();

    // Only upgrade "upgraded".
    pubUpgrade(args: ["upgraded"], output: new RegExp(r"""
Resolving dependencies\.\.\..*
  not_upgraded 1\.0\.0
. upgraded 2\.0\.0 \(was 1\.0\.0\) \(3\.0\.0-dev available\)
""", multiLine: true));
  });
}
