import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("compiles a Dart file that imports a generated file to JS", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "version": "0.0.1",
          "transformers": ["myapp/transformer"]
        }),
            d.dir("lib", [d.file("transformer.dart", dartTransformer("munge"))]),
            d.dir("web", [d.file("main.dart", """
import "other.dart";
void main() => print(TOKEN);
"""), d.file("other.dart", """
library other;
const TOKEN = "before";
""")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      pubServe();
      requestShouldSucceed("main.dart.js", contains("(before, munge)"));
      endPubServe();
    });
  });
}
