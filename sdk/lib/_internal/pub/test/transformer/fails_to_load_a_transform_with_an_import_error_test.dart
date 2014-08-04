// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();

  // An import error will cause the isolate API to fail synchronously while
  // loading the transformer.
  withBarbackVersions("any", () {
    integration("fails to load a transform with an import error", () {
      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
        d.dir("lib", [d.dir("src", [
          d.file("transformer.dart", "import 'does/not/exist.dart';")
        ])])
      ]).create();

      createLockFile('myapp', pkg: ['barback']);
      var pub = startPubServe();
      pub.stderr.expect("'Unhandled exception:");
      pub.stderr.expect(startsWith("Uncaught Error: Failure getting "));
      pub.shouldExit(1);
    });
  });
}
