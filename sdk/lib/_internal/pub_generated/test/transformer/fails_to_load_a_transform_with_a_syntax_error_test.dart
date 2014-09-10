library pub_tests;
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("fails to load a transform with a syntax error", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
            d.dir(
                "lib",
                [d.dir("src", [d.file("transformer.dart", "syntax error")])])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var pub = startPubServe();
      pub.stderr.expect(contains("unexpected token 'syntax'"));
      pub.shouldExit(1);
      pub.stderr.expect(never(contains('This is an unexpected error')));
    });
  });
}
