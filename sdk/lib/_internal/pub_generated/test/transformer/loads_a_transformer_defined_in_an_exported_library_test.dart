// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("loads a transformer defined in an exported library", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp"]
        }),
            d.dir(
                "lib",
                [
                    d.file("myapp.dart", "export 'src/transformer.dart';"),
                    d.dir("src", [d.file("transformer.dart", REWRITE_TRANSFORMER)])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      pubServe();
      requestShouldSucceed("foo.out", "foo.out");
      endPubServe();
    });
  });
}
