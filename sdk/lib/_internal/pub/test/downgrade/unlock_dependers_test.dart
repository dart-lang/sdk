// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("downgrades a locked package's dependers in order to get it to "
      "min version", () {
    servePackages([
      packageMap("foo", "2.0.0", {"bar": ">1.0.0"}),
      packageMap("bar", "2.0.0")
    ]);

    d.appDir({"foo": "any", "bar": "any"}).create();

    pubGet();

    d.packagesDir({
      "foo": "2.0.0",
      "bar": "2.0.0"
    }).validate();

    servePackages([
      packageMap("foo", "1.0.0", {"bar": "any"}),
      packageMap("bar", "1.0.0")
    ]);

    pubDowngrade(args: ['bar']);

    d.packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0"
    }).validate();
  });
}
