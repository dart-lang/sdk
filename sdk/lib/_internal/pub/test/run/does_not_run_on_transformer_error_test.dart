// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

const SCRIPT = """
main() {
  print("should not get here!");
}
""";

const TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class FailingTransformer extends Transformer {
  FailingTransformer.asPlugin();

  String get allowedExtensions => '.dart';

  void apply(Transform transform) {
    // Don't run on the transformer itself.
    if (transform.primaryInput.id.path.startsWith("lib")) return;
    transform.logger.error('\${transform.primaryInput.id}.');
  }
}
""";

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration('does not run if a transformer has an error', () {
      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
        d.dir("lib", [
          d.dir("src", [
            d.file("transformer.dart", TRANSFORMER)
          ])
        ]),
        d.dir("bin", [
          d.file("script.dart", SCRIPT)
        ])
      ]).create();

      createLockFile('myapp', pkg: ['barback']);

      var pub = pubRun(args: ["script"]);

      pub.stderr.expect("[Error from Failing]:");
      pub.stderr.expect("myapp|bin/script.dart.");

      // Note: no output from the script.
      pub.shouldExit();
    });
  });
}
