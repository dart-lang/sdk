// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('requires the dependency name to match the remote pubspec name', () {
    ensureGit();

    git('foo.git', [
      libDir('foo'),
      libPubspec('foo', '1.0.0')
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "weirdname": {"git": "../foo.git"}
        }
      })
    ]).scheduleCreate();

    // TODO(nweiz): clean up this RegExp when either issue 4706 or 4707 is
    // fixed.
    schedulePub(args: ['install'],
        error: const RegExp(r'^The name you specified for your dependency, '
            '"weirdname", doesn\'t match the name "foo" in its '
            r'pubspec\.'),
        exitCode: 1);

    run();
  });
}
