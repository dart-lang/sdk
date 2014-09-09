library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("fails to load a non-existent transform", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/transform"]
        })]).create();
      var pub = startPubServe();
      pub.stderr.expect(
          'Transformer library "package:myapp/transform.dart" not found.');
      pub.shouldExit(1);
    });
  });
}
