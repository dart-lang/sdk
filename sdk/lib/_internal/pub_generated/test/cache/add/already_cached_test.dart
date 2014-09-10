library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('does nothing if the package is already cached', () {
    servePackages((builder) {
      builder.serve("foo", "1.2.3");
    });
    schedulePub(
        args: ["cache", "add", "foo"],
        output: 'Downloading foo 1.2.3...');
    schedulePub(
        args: ["cache", "add", "foo"],
        output: 'Already cached foo 1.2.3.');
    d.cacheDir({
      "foo": "1.2.3"
    }).validate();
  });
}
