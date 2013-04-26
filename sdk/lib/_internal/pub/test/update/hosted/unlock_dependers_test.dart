// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("updates a locked package's dependers in order to get it to max "
      "version", () {
    servePackages([
      packageMap("foo", "1.0.0", [dependencyMap("bar", "<2.0.0")]),
      packageMap("bar", "1.0.0")
    ]);

    d.appDir([dependencyMap("foo"), dependencyMap("bar")]).create();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0"
    }).validate();

    servePackages([
      packageMap("foo", "2.0.0", [dependencyMap("bar", "<3.0.0")]),
      packageMap("bar", "2.0.0")
    ]);

    schedulePub(args: ['update', 'bar'],
        output: new RegExp(r"Dependencies updated!$"));

    d.packagesDir({
      "foo": "2.0.0",
      "bar": "2.0.0"
    }).validate();
  });
}
