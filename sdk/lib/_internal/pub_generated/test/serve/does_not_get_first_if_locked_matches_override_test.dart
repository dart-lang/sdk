library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("does not get if the locked version matches the override", () {
    d.dir("foo", [d.libPubspec("foo", "0.0.1"), d.libDir("foo")]).create();
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": "any"
        },
        "dependency_overrides": {
          "foo": {
            "path": "../foo",
            "version": ">=0.0.1"
          }
        }
      })]).create();
    pubGet();
    pubServe(shouldGetFirst: false);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo";');
    endPubServe();
  });
}
