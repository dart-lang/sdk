library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("doesn't crash if an unused .dart file has a syntax error", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
            d.dir(
                "lib",
                [
                    d.dir(
                        "src",
                        [
                            d.file("transformer.dart", REWRITE_TRANSFORMER),
                            d.file("unused.dart", "(*&^#@")])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var server = pubServe();
      requestShouldSucceed("foo.out", "foo.out");
      endPubServe();
    });
  });
}
