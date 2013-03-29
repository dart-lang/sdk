// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  group('requires', () {
    integration('a pubspec', () {
      d.dir(appPath, []).create();

      schedulePub(args: ['update'],
          error: new RegExp(r'^Could not find a file named "pubspec.yaml"'),
          exitCode: 1);
    });

    integration('a pubspec with a "name" key', () {
      d.dir(appPath, [
        d.pubspec({"dependencies": {"foo": null}})
      ]).create();

      schedulePub(args: ['update'],
          error: new RegExp(r'^pubspec.yaml is missing the required "name" '
              r'field \(e\.g\. "name: myapp"\)\.'),
          exitCode: 1);
    });
  });

  integration('adds itself to the packages', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    d.dir(appPath, [
      d.pubspec({"name": "myapp_name"}),
      d.libDir('myapp_name')
    ]).create();

    schedulePub(args: ['update'],
        output: new RegExp(r"Dependencies updated!$"));

    d.dir(packagesPath, [
      d.dir("myapp_name", [
        d.file('myapp_name.dart', 'main() => "myapp_name";')
      ])
    ]).validate();
  });

  integration('does not adds itself to the packages if it has no "lib" '
      'directory', () {
    // The symlink should use the name in the pubspec, not the name of the
    // directory.
    d.dir(appPath, [
      d.pubspec({"name": "myapp_name"}),
    ]).create();

    schedulePub(args: ['update'],
        output: new RegExp(r"Dependencies updated!$"));

    d.dir(packagesPath, [
      d.nothing("myapp_name")
    ]).validate();
  });

  integration('does not add a package if it does not have a "lib" '
      'directory', () {
    // Using a path source, but this should be true of all sources.
    d.dir('foo', [
      d.libPubspec('foo', '0.0.0-not.used')
    ]).create();

    d.dir(appPath, [
      d.pubspec({"name": "myapp", "dependencies": {"foo": {"path": "../foo"}}})
    ]).create();

    schedulePub(args: ['update'],
        output: new RegExp(r"Dependencies updated!$"));

    d.packagesDir({"foo": null}).validate();
  });
}
