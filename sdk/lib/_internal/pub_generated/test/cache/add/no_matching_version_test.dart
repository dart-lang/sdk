library pub_tests;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('fails if no version matches the version constraint', () {
    servePackages((builder) {
      builder.serve("foo", "1.2.2");
      builder.serve("foo", "1.2.3");
    });
    schedulePub(
        args: ["cache", "add", "foo", "-v", ">2.0.0"],
        error: 'Package foo has no versions that match >2.0.0.',
        exitCode: 1);
  });
}
