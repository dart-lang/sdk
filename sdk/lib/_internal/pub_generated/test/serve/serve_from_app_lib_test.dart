library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("'packages' URLs look in the app's lib directory", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir(
                "lib",
                [
                    d.file("lib.dart", "foo() => 'foo';"),
                    d.dir("sub", [d.file("lib.dart", "bar() => 'bar';")])])]).create();
    pubServe();
    requestShouldSucceed("packages/myapp/lib.dart", "foo() => 'foo';");
    requestShouldSucceed("packages/myapp/sub/lib.dart", "bar() => 'bar';");
    requestShouldSucceed("foo/packages/myapp/lib.dart", "foo() => 'foo';");
    requestShouldSucceed("a/b/packages/myapp/sub/lib.dart", "bar() => 'bar';");
    endPubServe();
  });
}
