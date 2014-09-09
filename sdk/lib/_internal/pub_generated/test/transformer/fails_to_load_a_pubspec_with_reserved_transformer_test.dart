library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("fails to load a pubspec with reserved transformer", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["\$nonexistent"]
        }),
            d.dir(
                "lib",
                [d.dir("src", [d.file("transformer.dart", REWRITE_TRANSFORMER)])])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var pub = startPubServe();
      pub.stderr.expect(
          contains(
              'Invalid transformer config: Unsupported '
                  'built-in transformer \$nonexistent.'));
      pub.shouldExit(exit_codes.DATA);
    });
  });
}
