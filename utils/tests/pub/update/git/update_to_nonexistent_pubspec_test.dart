// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/unittest.dart';

main() {
  test("updates Git packages to a nonexistent pubspec", () {
    ensureGit();

    var repo = git('foo.git', [
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]);
    repo.scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    repo.scheduleGit(['rm', 'pubspec.yaml']);
    repo.scheduleGit(['commit', '-m', 'delete']);

    schedulePub(args: ['update'],
        error: const RegExp(r'Package "foo" doesn' "'" r't have a '
            r'pubspec.yaml file.'),
        exitCode: 1);

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    run();
  });
}
