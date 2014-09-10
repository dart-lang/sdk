library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("runs a local transform on the application package", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
            d.dir("lib", [d.dir("src", [d.file("transformer.dart", REWRITE_TRANSFORMER)])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      pubServe();
      requestShouldSucceed("foo.out", "foo.out");
      endPubServe();
    });
  });
}
