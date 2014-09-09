library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('does not request versions if the lockfile is up to date', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "1.1.0");
      builder.serve("foo", "1.2.0");
    });
    d.appDir({
      "foo": "any"
    }).create();
    pubGet();
    getRequestedPaths();
    pubGet();
    d.cacheDir({
      "foo": "1.2.0"
    }).validate();
    d.packagesDir({
      "foo": "1.2.0"
    }).validate();
    getRequestedPaths().then((paths) {
      expect(paths, isEmpty);
    });
  });
}
