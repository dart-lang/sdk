// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration(
      "gets first if a git dependency's ref doesn't match the one in "
          "the lock file",
      () {
    var repo =
        d.git('foo.git', [d.libDir('foo', 'before'), d.libPubspec('foo', '1.0.0')]);
    repo.create();
    var commit1 = repo.revParse('HEAD');

    d.git(
        'foo.git',
        [d.libDir('foo', 'after'), d.libPubspec('foo', '1.0.0')]).commit();

    var commit2 = repo.revParse('HEAD');

    // Lock it to the ref of the first commit.
    d.appDir({
      "foo": {
        "git": {
          "url": "../foo.git",
          "ref": commit1
        }
      }
    }).create();

    pubGet();

    // Change the commit in the pubspec.
    d.appDir({
      "foo": {
        "git": {
          "url": "../foo.git",
          "ref": commit2
        }
      }
    }).create();

    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "after";');
    endPubServe();
  });
}
