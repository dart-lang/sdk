// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  // This is a regression test for issue #17198.
  initConfig();
  withBarbackVersions("any", () {
    integration(
        "compiles a Dart file that imports a generated file to JS " "outside web/",
        () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "version": "0.0.1",
          "transformers": ["myapp/transformer"]
        }),
            d.dir("lib", [d.file("transformer.dart", dartTransformer("munge"))]),
            d.dir("test", [d.file("main.dart", """
import "other.dart";
void main() => print(TOKEN);
"""), d.file("other.dart", """
library other;
const TOKEN = "before";
""")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      pubServe(args: ["test"]);
      requestShouldSucceed(
          "main.dart.js",
          contains("(before, munge)"),
          root: "test");
      endPubServe();
    });
  });
}
