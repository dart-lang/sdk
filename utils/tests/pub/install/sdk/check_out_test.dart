// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/unittest.dart';

main() {
  test('checks out a package from the SDK', () {
    dir(sdkPath, [
      file('revision', '1234'),
      dir('pkg', [
        dir('foo', [
          libDir('foo', 'foo 0.0.1234'),
          libPubspec('foo', '0.0.0-not.used')
        ])
      ])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({"name": "myapp", "dependencies": {"foo": {"sdk": "foo"}}})
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    packagesDir({"foo": "0.0.1234"}).scheduleValidate();

    run();
  });
}
