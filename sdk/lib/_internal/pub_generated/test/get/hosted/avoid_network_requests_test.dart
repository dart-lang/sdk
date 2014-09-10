library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('only requests versions that are needed during solving', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "1.1.0");
      builder.serve("foo", "1.2.0");
      builder.serve("bar", "1.0.0");
      builder.serve("bar", "1.1.0");
      builder.serve("bar", "1.2.0");
    });
    d.appDir({
      "foo": "any"
    }).create();
    pubGet();
    getRequestedPaths();
    d.appDir({
      "foo": "any",
      "bar": "any"
    }).create();
    pubGet();
    d.packagesDir({
      "foo": "1.2.0",
      "bar": "1.2.0"
    }).validate();
    getRequestedPaths().then((paths) {
      expect(
          paths,
          unorderedEquals(
              [
                  "api/packages/bar",
                  "api/packages/bar/versions/1.2.0",
                  "packages/bar/versions/1.2.0.tar.gz"]));
    });
  });
}
