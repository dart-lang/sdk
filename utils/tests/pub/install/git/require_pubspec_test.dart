// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('requires the dependency to have a pubspec', () {
    ensureGit();

    git('foo.git', [
      libDir('foo')
    ]).scheduleCreate();

    appDir([{"git": "../foo.git"}]).scheduleCreate();

    // TODO(nweiz): clean up this RegExp when either issue 4706 or 4707 is
    // fixed.
    schedulePub(args: ['install'],
        error: const RegExp('^Package "foo" doesn\'t have a '
            'pubspec.yaml file.'),
        exitCode: 1);

    run();
  });
}
