// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

const TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class RewriteTransformer extends Transformer {
  RewriteTransformer.asPlugin();

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) => throw new Exception('oh no!');
}
""";

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("outputs error to JSON in a failed build", () {
      // Loading transformers takes several seconds, so make sure we don't
      // timeout.
      currentSchedule.timeout *= 2;

      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp"]
        }),
            d.dir("lib", [d.file("transformer.dart", TRANSFORMER)]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      schedulePub(args: ["build", "--format", "json"], outputJson: {
        "buildResult": "failure",
        "errors": [{
            "error": startsWith(
                "Transform Rewrite on myapp|web/foo.txt " "threw error: oh no!")
          }],
        "log": []
      }, exitCode: exit_codes.DATA);
    });
  });
}
