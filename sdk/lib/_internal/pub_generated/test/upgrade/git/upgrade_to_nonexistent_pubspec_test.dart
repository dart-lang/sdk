// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("upgrades Git packages to a nonexistent pubspec", () {
    ensureGit();

    var repo =
        d.git('foo.git', [d.libDir('foo'), d.libPubspec('foo', '1.0.0')]);
    repo.create();

    d.appDir({
      "foo": {
        "git": "../foo.git"
      }
    }).create();

    pubGet();

    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo";')])]).validate();

    repo.runGit(['rm', 'pubspec.yaml']);
    repo.runGit(['commit', '-m', 'delete']);

    pubUpgrade(
        error: new RegExp(
            r'Could not find a file named "pubspec.yaml" ' r'in "[^\n]*"\.'));

    d.dir(
        packagesPath,
        [d.dir('foo', [d.file('foo.dart', 'main() => "foo";')])]).validate();
  });
}
