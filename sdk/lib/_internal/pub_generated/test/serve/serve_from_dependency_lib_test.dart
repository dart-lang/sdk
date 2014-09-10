library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("'packages' URLs look in the dependency's lib directory", () {
    d.dir(
        "foo",
        [
            d.libPubspec("foo", "0.0.1"),
            d.dir(
                "lib",
                [
                    d.file("lib.dart", "foo() => 'foo';"),
                    d.dir("sub", [d.file("lib.dart", "bar() => 'bar';")])])]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      })]).create();
    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/foo/lib.dart", "foo() => 'foo';");
    requestShouldSucceed("packages/foo/sub/lib.dart", "bar() => 'bar';");
    requestShouldSucceed("foo/packages/foo/lib.dart", "foo() => 'foo';");
    requestShouldSucceed("a/b/packages/foo/sub/lib.dart", "bar() => 'bar';");
    endPubServe();
  });
}
