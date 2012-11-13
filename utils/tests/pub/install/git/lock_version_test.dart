// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('keeps a Git package locked to the version in the lockfile', () {
    ensureGit();

    git('foo.git', [
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    // This install should lock the foo.git dependency to the current revision.
    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    // Delete the packages path to simulate a new checkout of the application.
    dir(packagesPath).scheduleDelete();

    git('foo.git', [
      libDir('foo', 'foo 2'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCommit();

    // This install shouldn't update the foo.git dependency due to the lockfile.
    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ])
    ]).scheduleValidate();

    run();
  });
}
