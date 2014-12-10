// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

// Regression test for issue 21726.
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("runs a dart2js transformer before a local transformer", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": [r"$dart2js", "myapp/src/transformer"]
        }),
            d.dir("lib", [d.dir("src", [d.file("transformer.dart", REWRITE_TRANSFORMER)])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      pubServe();
      requestShouldSucceed("foo.out", "foo.out");
      endPubServe();
    });
  });
}
