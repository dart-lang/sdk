// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('resolves version constraints from a pub server', () {
    servePackages([
      packageMap("foo", "1.2.3", {"baz": ">=2.0.0"}),
      packageMap("bar", "2.3.4", {"baz": "<3.0.0"}),
      packageMap("baz", "2.0.3"),
      packageMap("baz", "2.0.4"),
      packageMap("baz", "3.0.1")
    ]);

    d.appDir({"foo": "any", "bar": "any"}).create();

    pubGet();

    d.cacheDir({
      "foo": "1.2.3",
      "bar": "2.3.4",
      "baz": "2.0.4"
    }).validate();

    d.packagesDir({
      "foo": "1.2.3",
      "bar": "2.3.4",
      "baz": "2.0.4"
    }).validate();
  });
}
