library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("runs a local transformer on a dependency", () {
      d.dir("foo", [d.pubspec({
          "name": "foo",
          "version": "0.0.1",
          "transformers": ["foo/transformer"]
        }),
            d.dir(
                "lib",
                [
                    d.file("transformer.dart", REWRITE_TRANSFORMER),
                    d.file("foo.txt", "foo")])]).create();
      d.dir(appPath, [d.appPubspec({
          "foo": {
            "path": "../foo"
          }
        })]).create();
      createLockFile('myapp', sandbox: ['foo'], pkg: ['barback']);
      pubServe();
      requestShouldSucceed("packages/foo/foo.out", "foo.out");
      endPubServe();
    });
  });
}
