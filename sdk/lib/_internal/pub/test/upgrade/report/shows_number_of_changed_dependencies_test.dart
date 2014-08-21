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
    servePackages((builder) {
      builder.serve("a", "1.0.0");
      builder.serve("b", "1.0.0");
      builder.serve("c", "2.0.0");
    });

    d.appDir({
      "a": "any"
    }).create();

    // One dependency changed.
    pubUpgrade(output: new RegExp(r"Changed 1 dependency!$"));

    // Remove one and add two.
    d.appDir({
      "b": "any",
      "c": "any"
    }).create();

    pubUpgrade(output: new RegExp(r"Changed 3 dependencies!$"));

    // Don't change anything.
    pubUpgrade(output: new RegExp(r"No dependencies changed.$"));
  });
}
