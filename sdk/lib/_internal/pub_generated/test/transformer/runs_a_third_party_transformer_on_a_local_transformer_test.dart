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
    integration("runs a third-party transformer on a local transformer", () {
      d.dir(
          "foo",
          [
              d.libPubspec("foo", '1.0.0'),
              d.dir("lib", [d.file("transformer.dart", dartTransformer('foo'))])]).create();

      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["foo/transformer", "myapp/transformer"],
          "dependencies": {
            "foo": {
              "path": "../foo"
            }
          }
        }),
            d.dir("lib", [d.file("transformer.dart", dartTransformer('myapp'))]),
            d.dir("web", [d.file("main.dart", 'const TOKEN = "main.dart";')])]).create();

      createLockFile('myapp', sandbox: ['foo'], pkg: ['barback']);

      pubServe();
      requestShouldSucceed(
          "main.dart",
          'const TOKEN = "((main.dart, foo), (myapp, foo))";');
      endPubServe();
    });
  });
}
