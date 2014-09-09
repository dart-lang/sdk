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
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
            d.dir(
                "lib",
                [
                    d.file("lib.dart", LIB),
                    d.dir("src", [d.file("transformer.dart", TRANSFORMER)])]),
            d.dir("bin", [d.file("script.dart", SCRIPT)])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var pub = pubRun(args: ["script"]);
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
