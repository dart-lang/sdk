// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/unittest.dart';

main() {
  test("updates one locked pub server package's dependencies if it's "
      "necessary", () {
    servePackages([
      package("foo", "1.0.0", [dependency("foo-dep")]),
      package("foo-dep", "1.0.0")
    ]);

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "foo-dep": "1.0.0"
    }).scheduleValidate();

    servePackages([
      package("foo", "2.0.0", [dependency("foo-dep", ">1.0.0")]),
      package("foo-dep", "2.0.0")
    ]);

    schedulePub(args: ['update', 'foo'],
        output: const RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "2.0.0",
      "foo-dep": "2.0.0"
    }).scheduleValidate();

    run();
  });
}
