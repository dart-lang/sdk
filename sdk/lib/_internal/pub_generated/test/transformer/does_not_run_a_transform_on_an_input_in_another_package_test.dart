// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("does not run a transform on an input in another package", () {
      d.dir("foo", [d.pubspec({
          "name": "foo",
          "version": "0.0.1",
          "transformers": ["foo/transformer"]
        }),
            d.dir(
                "lib",
                [
                    d.file("transformer.dart", REWRITE_TRANSFORMER),
                    d.file("foo.txt", "foo")])]).create();

      d.dir(appPath, [d.appPubspec({
          "foo": {
            "path": "../foo"
          }
        }), d.dir("lib", [d.file("bar.txt", "bar")])]).create();

      createLockFile('myapp', sandbox: ['foo'], pkg: ['barback']);

      pubServe();
      requestShould404("packages/myapp/bar.out");
      endPubServe();
    });
  });
}
