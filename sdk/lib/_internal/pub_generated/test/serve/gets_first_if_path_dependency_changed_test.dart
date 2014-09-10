library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration(
      "gets first if a path dependency's path doesn't match the one in "
          "the lock file",
      () {
    d.dir(
        "foo-before",
        [d.libPubspec("foo", "0.0.1"), d.libDir("foo", "before")]).create();
    d.dir(
        "foo-after",
        [d.libPubspec("foo", "0.0.1"), d.libDir("foo", "after")]).create();
    d.appDir({
      "foo": {
        "path": "../foo-before"
      }
    }).create();
    pubGet();
    d.appDir({
      "foo": {
        "path": "../foo-after"
      }
    }).create();
    pubServe(shouldGetFirst: true);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "after";');
    endPubServe();
  });
}
