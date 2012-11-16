// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('checks out a package at a specific revision from Git', () {
    ensureGit();

    var repo = git('foo.git', [
      libDir('foo', 'foo 1'),
      libPubspec('foo', '1.0.0')
    ]);
    repo.scheduleCreate();
    var commit = repo.revParse('HEAD');

    git('foo.git', [
      libDir('foo', 'foo 2'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCommit();

    appDir([{"git": {"url": "../foo.git", "ref": commit}}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo 1";')
      ])
    ]).scheduleValidate();

    run();
  });
}
