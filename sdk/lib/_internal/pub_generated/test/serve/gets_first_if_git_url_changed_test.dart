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
      "gets first if a git dependency's url doesn't match the one in "
          "the lock file",
      () {
    d.git(
        "foo-before.git",
        [d.libPubspec("foo", "1.0.0"), d.libDir("foo", "before")]).create();

    d.git(
        "foo-after.git",
        [d.libPubspec("foo", "1.0.0"), d.libDir("foo", "after")]).create();

    d.appDir({
      "foo": {
        "git": "../foo-before.git"
      }
    }).create();

    pubGet();

    // Change the path in the pubspec.
    d.appDir({
      "foo": {
        "git": "../foo-after.git"
      }
    }).create();

    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "after";');
    endPubServe();
  });
}
