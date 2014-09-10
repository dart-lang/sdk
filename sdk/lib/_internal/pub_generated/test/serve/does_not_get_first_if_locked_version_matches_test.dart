library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration(
      "does not get if the locked version of a dependency is allowed "
          "by the pubspec's constraint",
      () {
    d.dir("foo", [d.libPubspec("foo", "0.0.1"), d.libDir("foo")]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo",
          "version": ">=0.0.1"
        }
      })]).create();
    pubGet();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo",
          "version": "<2.0.0"
        }
      })]).create();
    pubServe(shouldGetFirst: false);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo";');
    endPubServe();
  });
}
