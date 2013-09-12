// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();

  integration("fails to load a pubspec with reserved transformer config", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": [{"myapp/src/transformer": {'include': 'something'}}]
      }),
      d.dir("lib", [d.dir("src", [
        d.file("transformer.dart", REWRITE_TRANSFORMER)
      ])])
    ]).create();

    createLockFile('myapp', pkg: ['barback']);

    var pub = startPub(args: ['serve', '--port=0']);
    expect(pub.nextErrLine(), completion(startsWith('Could not parse ')));
    expect(pub.nextErrLine(), completion(equals('Configuration for '
        'transformer myapp/src/transformer may not include reserved key '
        '"include".')));
    pub.shouldExit(1);
  });
}
