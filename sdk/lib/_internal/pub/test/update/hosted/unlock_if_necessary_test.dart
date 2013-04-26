// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("updates one locked pub server package's dependencies if it's "
      "necessary", () {
    servePackages([
      packageMap("foo", "1.0.0", [dependencyMap("foo-dep")]),
      packageMap("foo-dep", "1.0.0")
    ]);

    d.appDir([dependencyMap("foo")]).create();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.packagesDir({
      "foo": "1.0.0",
      "foo-dep": "1.0.0"
    }).validate();

    servePackages([
      packageMap("foo", "2.0.0", [dependencyMap("foo-dep", ">1.0.0")]),
      packageMap("foo-dep", "2.0.0")
    ]);

    schedulePub(args: ['update', 'foo'],
        output: new RegExp(r"Dependencies updated!$"));

    d.packagesDir({
      "foo": "2.0.0",
      "foo-dep": "2.0.0"
    }).validate();
  });
}
