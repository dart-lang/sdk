// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../../../pkg/pathos/lib/path.dart' as path;
import '../../../../pkg/unittest/lib/unittest.dart';

import '../test_pub.dart';

main() {
  initConfig();
  integration('replaces a broken "packages" symlink', () {
    dir(appPath, [
      appPubspec([]),
      libDir('foo'),
      dir("bin")
    ]).scheduleCreate();

    // Create a broken "packages" symlink in "bin".
    scheduleSymlink("nonexistent", path.join(appPath, "packages"));

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    dir(appPath, [
      dir("bin", [
        dir("packages", [
          dir("myapp", [
            file('foo.dart', 'main() => "foo";')
          ])
        ])
      ])
    ]).scheduleValidate();
  });

  integration('replaces a broken secondary "packages" symlink', () {
    dir(appPath, [
      appPubspec([]),
      libDir('foo'),
      dir("bin")
    ]).scheduleCreate();

    // Create a broken "packages" symlink in "bin".
    scheduleSymlink("nonexistent", path.join(appPath, "bin", "packages"));

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    dir(appPath, [
      dir("bin", [
        dir("packages", [
          dir("myapp", [
            file('foo.dart', 'main() => "foo";')
          ])
        ])
      ])
    ]).scheduleValidate();
  });
}
