// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

const SCRIPT = """
import "package:myapp/lib.dart";
main() {
  callLib();
}
""";

const LIB = """
callLib() {
  print("lib");
}
""";

// Make it lazy so that "lib.dart" isn't transformed until after the process
// is started. Otherwise, since this tranformer modifies .dart files, it will
// be run while the transformers themselves are loading during pub run's
// startup.
const TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class LoggingTransformer extends Transformer implements LazyTransformer {
  LoggingTransformer.asPlugin();

  String get allowedExtensions => '.dart';

  void apply(Transform transform) {
    transform.logger.info('\${transform.primaryInput.id}.');
    transform.logger.warning('\${transform.primaryInput.id}.');
  }

  void declareOutputs(DeclaringTransform transform) {
    // TODO(rnystrom): Remove this when #19408 is fixed.
    transform.declareOutput(transform.primaryId);
  }
}
""";

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration('displays transformer log messages', () {
      d.dir(appPath, [
        d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
        d.dir("lib", [
          d.file("lib.dart", LIB),
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

      // Note that the info log is only displayed here because the test
      // harness runs pub in verbose mode. By default, only the warning would
      // be shown.
      pub.stdout.expect("[Info from Logging]:");
      pub.stdout.expect("myapp|bin/script.dart.");

      pub.stderr.expect("[Warning from Logging]:");
      pub.stderr.expect("myapp|bin/script.dart.");

      pub.stdout.expect("[Info from Logging]:");
      pub.stdout.expect("myapp|lib/lib.dart.");

      pub.stderr.expect("[Warning from Logging]:");
      pub.stderr.expect("myapp|lib/lib.dart.");

      pub.stdout.expect("lib");
      pub.shouldExit();
    });
  });
}
