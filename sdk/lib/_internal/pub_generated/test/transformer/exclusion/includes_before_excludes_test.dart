// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("applies includes before excludes if both are present", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": [{
              "myapp/src/transformer": {
                "\$include": ["web/a.txt", "web/b.txt"],
                "\$exclude": "web/a.txt"
              }
            }]
        }),
            d.dir("lib", [d.dir("src", [d.file("transformer.dart", REWRITE_TRANSFORMER)])]),
            d.dir(
                "web",
                [
                    d.file("a.txt", "a.txt"),
                    d.file("b.txt", "b.txt"),
                    d.file("c.txt", "c.txt")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      pubServe();
      requestShould404("a.out");
      requestShouldSucceed("b.out", "b.txt.out");
      requestShould404("c.out");
      endPubServe();
    });
  });
}
