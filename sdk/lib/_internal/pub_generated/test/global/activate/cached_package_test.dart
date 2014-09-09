import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('can activate an already cached package', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
    });
    schedulePub(args: ["cache", "add", "foo"]);
    schedulePub(args: ["global", "activate", "foo"], output: """
        Resolving dependencies...
        + foo 1.0.0
        Precompiling executables...
        Loading source assets...
        Activated foo 1.0.0.""");
    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages',
                [
                    d.dir('foo', [d.matcherFile('pubspec.lock', contains('1.0.0'))])])]).validate();
  });
}
