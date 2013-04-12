// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("unlocks dependencies if necessary to ensure that a new "
      "dependency is satisfied", () {
    servePackages([
      packageMap("foo", "1.0.0", [dependencyMap("bar", "<2.0.0")]),
      packageMap("bar", "1.0.0", [dependencyMap("baz", "<2.0.0")]),
      packageMap("baz", "1.0.0", [dependencyMap("qux", "<2.0.0")]),
      packageMap("qux", "1.0.0")
    ]);

    d.appDir([dependencyMap("foo")]).create();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "baz": "1.0.0",
      "qux": "1.0.0"
    }).validate();

    servePackages([
      packageMap("foo", "2.0.0", [dependencyMap("bar", "<3.0.0")]),
      packageMap("bar", "2.0.0", [dependencyMap("baz", "<3.0.0")]),
      packageMap("baz", "2.0.0", [dependencyMap("qux", "<3.0.0")]),
      packageMap("qux", "2.0.0"),
      packageMap("newdep", "2.0.0", [dependencyMap("baz", ">=1.5.0")])
    ]);

    d.appDir([dependencyMap("foo"), dependencyMap("newdep")]).create();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.packagesDir({
      "foo": "2.0.0",
      "bar": "2.0.0",
      "baz": "2.0.0",
      "qux": "1.0.0",
      "newdep": "2.0.0"
    }).validate();
  });
}
