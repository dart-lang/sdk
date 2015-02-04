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
    integration("runs a third-party transform on the application package", () {
      d.dir(
          "foo",
          [
              d.libPubspec("foo", '1.0.0'),
              d.dir("lib", [d.file("foo.dart", REWRITE_TRANSFORMER)])]).create();

      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "dependencies": {
            "foo": {
              "path": "../foo"
            }
          },
          "transformers": ["foo"]
        }), d.dir("web", [d.file("foo.txt", "foo")])]).create();

      createLockFile('myapp', sandbox: ['foo'], pkg: ['barback']);

      pubServe();
      requestShouldSucceed("foo.out", "foo.out");
      endPubServe();
    });
  });
}
