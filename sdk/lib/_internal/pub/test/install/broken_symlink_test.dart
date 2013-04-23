// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import 'package:pathos/path.dart' as path;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('replaces a broken "packages" symlink', () {
    d.dir(appPath, [
      d.appPubspec([]),
      d.libDir('foo'),
      d.dir("bin")
    ]).create();

    // Create a broken "packages" symlink in "bin".
    scheduleSymlink("nonexistent", path.join(appPath, "packages"));

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(appPath, [
      d.dir("bin", [
        d.dir("packages", [
          d.dir("myapp", [
            d.file('foo.dart', 'main() => "foo";')
          ])
        ])
      ])
    ]).validate();
  });

  integration('replaces a broken secondary "packages" symlink', () {
    d.dir(appPath, [
      d.appPubspec([]),
      d.libDir('foo'),
      d.dir("bin")
    ]).create();

    // Create a broken "packages" symlink in "bin".
    scheduleSymlink("nonexistent", path.join(appPath, "bin", "packages"));

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    d.dir(appPath, [
      d.dir("bin", [
        d.dir("packages", [
          d.dir("myapp", [
            d.file('foo.dart', 'main() => "foo";')
          ])
        ])
      ])
    ]).validate();
  });
}
