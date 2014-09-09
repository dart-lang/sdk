library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('does not request a pubspec for a cached package', () {
    servePackages((builder) => builder.serve("foo", "1.2.3"));
    d.appDir({
      "foo": "1.2.3"
    }).create();
    pubGet();
    getRequestedPaths();
    d.cacheDir({
      "foo": "1.2.3"
    }).validate();
    d.packagesDir({
      "foo": "1.2.3"
    }).validate();
    pubGet();
    getRequestedPaths().then((paths) {
      expect(paths, isNot(contains("packages/foo/versions/1.2.3.yaml")));
    });
  });
}
