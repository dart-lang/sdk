// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  // A syntax error will cause the analyzer to fail to parse the transformer
  // when attempting to rewrite its imports.
  integration("fails to load a transform with a syntax error", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": ["myapp/src/transformer"]
      }),
      d.dir("lib", [d.dir("src", [
        d.file("transformer.dart", "syntax error")
      ])])
    ]).create();

    createLockFile('myapp', pkg: ['barback']);

    var pub = startPub(args: ['serve', '--port=0', "--hostname=127.0.0.1"]);
    expect(pub.nextErrLine(), completion(startsWith('Error on line')));
    pub.shouldExit(1);
    expect(pub.remainingStderr(),
        completion(isNot(contains('This is an unexpected error'))));
  });
}
