// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/unittest.dart';

main() {
  test("doesn't update one locked Git package's dependencies if it's not "
      "necessary", () {
    ensureGit();

    git('foo.git', [
      libDir('foo'),
      libPubspec("foo", "1.0.0", [{"git": "../foo-dep.git"}])
    ]).scheduleCreate();

    git('foo-dep.git', [
      libDir('foo-dep'),
      libPubspec('foo-dep', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ]),
      dir('foo-dep', [
        file('foo-dep.dart', 'main() => "foo-dep";')
      ])
    ]).scheduleValidate();

    git('foo.git', [
      libDir('foo', 'foo 2'),
      libPubspec("foo", "1.0.0", [{"git": "../foo-dep.git"}])
    ]).scheduleCreate();

    git('foo-dep.git', [
      libDir('foo-dep', 'foo-dep 2'),
      libPubspec('foo-dep', '1.0.0')
    ]).scheduleCommit();

    schedulePub(args: ['update', 'foo'],
        output: const RegExp(r"Dependencies updated!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 2";')
      ]),
      dir('foo-dep', [
        file('foo-dep.dart', 'main() => "foo-dep";')
      ]),
    ]).scheduleValidate();

    run();
  });
}
