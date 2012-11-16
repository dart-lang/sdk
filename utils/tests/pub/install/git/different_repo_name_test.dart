// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('doesn\'t require the repository name to match the name in the '
      'pubspec', () {
    ensureGit();

    git('foo.git', [
      libDir('weirdname'),
      libPubspec('weirdname', '1.0.0')
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "weirdname": {"git": "../foo.git"}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('weirdname', [
        file('weirdname.dart', 'main() => "weirdname";')
      ])
    ]).scheduleValidate();

    run();
  });
}
