// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test("removes a transitive dependency that's no longer depended on", () {
    servePackages([
      package("foo", "1.0.0", [dependency("shared-dep")]),
      package("bar", "1.0.0", [
        dependency("shared-dep"),
        dependency("bar-dep")
      ]),
      package("shared-dep", "1.0.0"),
      package("bar-dep", "1.0.0")
    ]);

    appDir([dependency("foo"), dependency("bar")]).scheduleCreate();

    schedulePub(args: ['update'],
        output: new RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": "1.0.0",
      "shared-dep": "1.0.0",
      "bar-dep": "1.0.0",
    }).scheduleValidate();

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['update'],
        output: new RegExp(r"Dependencies updated!$"));

    packagesDir({
      "foo": "1.0.0",
      "bar": null,
      "shared-dep": "1.0.0",
      "bar-dep": null,
    }).scheduleValidate();

    run();
  });
}
