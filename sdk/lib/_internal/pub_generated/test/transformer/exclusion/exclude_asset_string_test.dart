library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("allows a single string as the asset to exclude", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": [{
              "myapp/src/transformer": {
                "\$exclude": "web/foo.txt"
              }
            }]
        }),
            d.dir("lib", [d.dir("src", [d.file("transformer.dart", REWRITE_TRANSFORMER)])]),
            d.dir(
                "web",
                [
                    d.file("foo.txt", "foo"),
                    d.file("bar.txt", "bar"),
                    d.dir("sub", [d.file("foo.txt", "foo")])])]).create();
      createLockFile('myapp', pkg: ['barback']);
      pubServe();
      requestShould404("foo.out");
      requestShouldSucceed("sub/foo.out", "foo.out");
      requestShouldSucceed("bar.out", "bar.out");
      endPubServe();
    });
  });
}
