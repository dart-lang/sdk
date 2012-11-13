// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('includes transitive dependencies', () {
    dir(sdkPath, [
      file('revision', '1234'),
      dir('pkg', [
        dir('foo', [
          libDir('foo', 'foo 0.0.1234'),
          libPubspec('foo', '0.0.0-not.used', [{'sdk': 'bar'}])
        ]),
        dir('bar', [
          libDir('bar', 'bar 0.0.1234'),
          libPubspec('bar', '0.0.0-not.used')
        ])
      ])
    ]).scheduleCreate();

    dir(appPath, [
      appPubspec([{'sdk': 'foo'}])
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    packagesDir({
      'foo': '0.0.1234',
      'bar': '0.0.1234'
    }).scheduleValidate();

    run();
  });
}
