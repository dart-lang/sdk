// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../../../pkg/unittest/lib/unittest.dart';
import '../test_pub.dart';

main() {
  group('requires', () {
    integration('a pubspec', () {
      dir(appPath, []).scheduleCreate();

      schedulePub(args: ['update'],
          error: new RegExp(r'^Could not find a file named "pubspec.yaml"'),
          exitCode: 1);
    });

    integration('a pubspec with a "name" key', () {
      dir(appPath, [
        pubspec({"dependencies": {"foo": null}})
      ]).scheduleCreate();

      schedulePub(args: ['update'],
          error: new RegExp(r'^pubspec.yaml is missing the required "name" '
              r'field \(e\.g\. "name: myapp"\)\.'),
          exitCode: 1);
    });
  });

  integration('adds itself to the packages', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    dir(appPath, [
      pubspec({"name": "myapp_name"}),
      libDir('myapp_name')
    ]).scheduleCreate();

    schedulePub(args: ['update'],
        output: new RegExp(r"Dependencies updated!$"));

    dir(packagesPath, [
      dir("myapp_name", [
        file('myapp_name.dart', 'main() => "myapp_name";')
      ])
    ]).scheduleValidate();
  });

  integration('does not adds itself to the packages if it has no "lib" '
      'directory', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    dir(appPath, [
      pubspec({"name": "myapp_name"}),
    ]).scheduleCreate();

    schedulePub(args: ['update'],
        output: new RegExp(r"Dependencies updated!$"));

    dir(packagesPath, [
      nothing("myapp_name")
    ]).scheduleValidate();
  });

  integration('does not add a package if it does not have a "lib" '
      'directory', () {
    // Using an SDK source, but this should be true of all sources.
    dir(sdkPath, [
      file('version', '0.1.2.3'),
      dir('pkg', [
        dir('foo', [
          libPubspec('foo', '0.0.0-not.used')
        ])
      ])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({"name": "myapp", "dependencies": {"foo": {"sdk": "foo"}}})
    ]).scheduleCreate();

    schedulePub(args: ['update'],
        output: new RegExp(r"Dependencies updated!$"));

    packagesDir({"foo": null}).scheduleValidate();
  });
}
