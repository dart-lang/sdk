// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';

main() {
  initConfig();

  integration("doesn't support an invalid dart2js option", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": [{
          "\$dart2js": {"invalidOption": true}
        }]
      }),
      d.dir("lib", [d.dir("src", [
        d.file("transformer.dart", REWRITE_TRANSFORMER)
      ])])
    ]).create();

    createLockFile('myapp', pkg: ['barback']);

    // TODO(nweiz): This should provide more context about how the option got
    // passed to dart2js. See issue 16008.
    var pub = startPubServe();
    pub.stderr.expect('Unrecognized dart2js option "invalidOption".');
    pub.shouldExit(1);
  });
}
