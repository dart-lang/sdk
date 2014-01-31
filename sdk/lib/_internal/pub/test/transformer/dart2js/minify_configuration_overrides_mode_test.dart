// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';

main() {
  initConfig();

  integration("minify configuration overrides the mode", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": [{
          "\$dart2js": {"minify": true}
        }]
      }),
      d.dir("lib", [d.dir("src", [
        d.file("transformer.dart", REWRITE_TRANSFORMER)
      ])])
    ]).create();

    createLockFile('myapp', pkg: ['barback']);

    pubServe();
    requestShouldSucceed("main.dart.js", isMinifiedDart2JSOutput);
    endPubServe();
  });
}
