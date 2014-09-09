import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('installs and activates the best version of a package', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "1.2.3");
      builder.serve("foo", "2.0.0-wildly.unstable");
    });
    schedulePub(args: ["global", "activate", "foo"], output: """
        Resolving dependencies...
        + foo 1.2.3 (2.0.0-wildly.unstable available)
        Downloading foo 1.2.3...
        Precompiling executables...
        Loading source assets...
        Activated foo 1.2.3.""");
    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages',
                [
                    d.dir('foo', [d.matcherFile('pubspec.lock', contains('1.2.3'))])])]).validate();
  });
}
