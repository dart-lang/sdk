// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  // This is a regression test for https://dartbug.com/15180.
  initConfig();
  integration("does not get if the locked version matches the override", () {
    d.dir("foo", [d.libPubspec("foo", "0.0.1"), d.libDir("foo")]).create();

    // Get "foo" into the lock file.
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": "any"
        },
        "dependency_overrides": {
          "foo": {
            "path": "../foo",
            "version": ">=0.0.1"
          }
        }
      })]).create();
    pubGet();

    pubServe(shouldGetFirst: false);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo";');
    endPubServe();
  });
}
