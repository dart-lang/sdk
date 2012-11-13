// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('checks out packages transitively from Git', () {
    ensureGit();

    git('foo.git', [
      libDir('foo'),
      libPubspec('foo', '1.0.0', [{"git": "../bar.git"}])
    ]).scheduleCreate();

    git('bar.git', [
      libDir('bar'),
      libPubspec('bar', '1.0.0')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp("Dependencies installed!\$"));

    dir(cachePath, [
      dir('git', [
        dir('cache', [
          gitPackageRepoCacheDir('foo'),
          gitPackageRepoCacheDir('bar')
        ]),
        gitPackageRevisionCacheDir('foo'),
        gitPackageRevisionCacheDir('bar')
      ])
    ]).scheduleValidate();

    dir(packagesPath, [
      dir('foo', [
        file('foo.dart', 'main() => "foo";')
      ]),
      dir('bar', [
        file('bar.dart', 'main() => "bar";')
      ])
    ]).scheduleValidate();

    run();
  });
}
