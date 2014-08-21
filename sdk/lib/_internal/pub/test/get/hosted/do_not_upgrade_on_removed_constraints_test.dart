// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("doesn't upgrade dependencies whose constraints have been "
      "removed", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", deps: {"shared-dep": "any"});
      builder.serve("bar", "1.0.0", deps: {"shared-dep": "<2.0.0"});
      builder.serve("shared-dep", "1.0.0");
      builder.serve("shared-dep", "2.0.0");
    });

    d.appDir({"foo": "any", "bar": "any"}).create();

    pubGet();

    d.packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "shared-dep": "1.0.0"
    }).validate();

    d.appDir({"foo": "any"}).create();

    pubGet();

    d.packagesDir({
      "foo": "1.0.0",
      "bar": null,
      "shared-dep": "1.0.0"
    }).validate();
  });
}
