library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('adds the latest stable version of the package', () {
    servePackages((builder) {
      builder.serve("foo", "1.2.2");
      builder.serve("foo", "1.2.3");
      builder.serve("foo", "1.2.4-dev");
    });
    schedulePub(
        args: ["cache", "add", "foo"],
        output: 'Downloading foo 1.2.3...');
    d.cacheDir({
      "foo": "1.2.3"
    }).validate();
  });
}
