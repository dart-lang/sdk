// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test("updates a locked package's dependers in order to get it to max "
      "version", () {
    servePackages([
      package("foo", "1.0.0", [dependency("bar", "<2.0.0")]),
      package("bar", "1.0.0")
    ]);

    appDir([dependency("foo"), dependency("bar")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0"
    }).scheduleValidate();

    servePackages([
      package("foo", "2.0.0", [dependency("bar", "<3.0.0")]),
      package("bar", "2.0.0")
    ]);

    schedulePub(args: ['update', 'bar'],
        output: const RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "2.0.0",
      "bar": "2.0.0"
    }).scheduleValidate();

    run();
  });
}
