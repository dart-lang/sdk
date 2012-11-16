// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test("unlocks dependencies if necessary to ensure that a new dependency "
      "is satisfied", () {
    servePackages([
      package("foo", "1.0.0", [dependency("bar", "<2.0.0")]),
      package("bar", "1.0.0", [dependency("baz", "<2.0.0")]),
      package("baz", "1.0.0", [dependency("qux", "<2.0.0")]),
      package("qux", "1.0.0")
    ]);

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "baz": "1.0.0",
      "qux": "1.0.0"
    }).scheduleValidate();

    servePackages([
      package("foo", "2.0.0", [dependency("bar", "<3.0.0")]),
      package("bar", "2.0.0", [dependency("baz", "<3.0.0")]),
      package("baz", "2.0.0", [dependency("qux", "<3.0.0")]),
      package("qux", "2.0.0"),
      package("newdep", "2.0.0", [dependency("baz", ">=1.5.0")])
    ]);

    appDir([dependency("foo"), dependency("newdep")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    packagesDir({
      "foo": "2.0.0",
      "bar": "2.0.0",
      "baz": "2.0.0",
      "qux": "1.0.0",
      "newdep": "2.0.0"
    }).scheduleValidate();

    run();
  });
}
