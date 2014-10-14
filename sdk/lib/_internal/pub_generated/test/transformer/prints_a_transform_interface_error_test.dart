// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

final transformer = """
import 'dart:async';

import 'package:barback/barback.dart';

class RewriteTransformer extends Transformer {
  RewriteTransformer.asPlugin();

  String get allowedExtensions => '.txt';
}
""";

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("prints a transform interface error", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
            d.dir("lib", [d.dir("src", [d.file("transformer.dart", transformer)])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      var server = pubServe();
      server.stderr.expect(
          emitsLines(
              "Build error:\n" "Transform Rewrite on myapp|web/foo.txt threw error: Class "
                  "'RewriteTransformer' has no instance method 'apply'."));
      endPubServe();
    });
  });
}
