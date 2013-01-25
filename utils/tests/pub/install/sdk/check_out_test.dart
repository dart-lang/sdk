// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';

main() {
  integration('checks out a package from the SDK', () {
    dir(sdkPath, [
      file('version', '0.1.2.3'),
      dir('pkg', [
        dir('foo', [
          libDir('foo', 'foo 0.1.2+3'),
          libPubspec('foo', '0.0.0-not.used')
        ])
      ])
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({"name": "myapp", "dependencies": {"foo": {"sdk": "foo"}}})
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    packagesDir({"foo": "0.1.2+3"}).scheduleValidate();
  });
}
