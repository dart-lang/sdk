// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();

  integration("fails to load a pubspec with reserved transformer", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": ["\$nonexistent"]
      }),
      d.dir("lib", [d.dir("src", [
        d.file("transformer.dart", REWRITE_TRANSFORMER)
      ])])
    ]).create();

    createLockFile('myapp', pkg: ['barback']);

    var pub = startPubServe();
    pub.stderr.expect(emitsLines(
        'Error in pubspec for package "myapp" loaded from pubspec.yaml:\n'
        'Invalid transformer configuration for "transformers.\$nonexistent": '
            'Unsupported built-in transformer \$nonexistent.'));
    pub.shouldExit(1);
  });
}
