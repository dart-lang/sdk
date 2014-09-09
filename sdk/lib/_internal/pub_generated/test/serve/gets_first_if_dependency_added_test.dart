library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("gets first if a dependency is not in the lock file", () {
    d.dir("foo", [d.libPubspec("foo", "0.0.1"), d.libDir("foo")]).create();
    d.dir(appPath, [d.appPubspec()]).create();
    pubGet();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      })]).create();
    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo";');
    endPubServe();
  });
}
