// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("upgrades one locked pub server package's dependencies if it's "
      "necessary", () {
    servePackages([
      packageMap("foo", "1.0.0", {"foo_dep": "any"}),
      packageMap("foo_dep", "1.0.0")
    ]);

    d.appDir({"foo": "any"}).create();

    pubGet();

    d.packagesDir({
      "foo": "1.0.0",
      "foo_dep": "1.0.0"
    }).validate();

    servePackages([
      packageMap("foo", "2.0.0", {"foo_dep": ">1.0.0"}),
      packageMap("foo_dep", "2.0.0")
    ]);

    pubUpgrade(args: ['foo']);

    d.packagesDir({
      "foo": "2.0.0",
      "foo_dep": "2.0.0"
    }).validate();
  });
}
