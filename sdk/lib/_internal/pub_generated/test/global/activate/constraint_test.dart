import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('chooses the highest version that matches the constraint', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "1.0.1");
      builder.serve("foo", "1.1.0");
      builder.serve("foo", "1.2.3");
    });
    schedulePub(args: ["global", "activate", "foo", "<1.1.0"]);
    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages',
                [
                    d.dir('foo', [d.matcherFile('pubspec.lock', contains('1.0.1'))])])]).validate();
  });
}
