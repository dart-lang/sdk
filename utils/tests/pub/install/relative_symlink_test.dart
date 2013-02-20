// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../../../pkg/unittest/lib/unittest.dart';
import '../test_pub.dart';

main() {
  // Pub uses NTFS junction points to create links in the packages directory.
  // These (unlike the symlinks that are supported in Vista and later) do not
  // support relative paths. So this test, by design, will not pass on Windows.
  // So just skip it.
  if (Platform.operatingSystem == "windows") return;

  initConfig();
  integration('uses a relative symlink for the self link', () {
    dir(appPath, [
      appPubspec([]),
      libDir('foo')
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    scheduleRename(appPath, "moved");

    dir("moved", [
      dir("packages", [
        dir("myapp", [
          file('foo.dart', 'main() => "foo";')
        ])
      ])
    ]).scheduleValidate();
  });

  integration('uses a relative symlink for secondary packages directory', () {
    dir(appPath, [
      appPubspec([]),
      libDir('foo'),
      dir("bin")
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    scheduleRename(appPath, "moved");

    dir("moved", [
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
