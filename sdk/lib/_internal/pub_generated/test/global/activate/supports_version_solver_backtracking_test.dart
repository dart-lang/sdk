import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration('performs verison solver backtracking if necessary', () {
    servePackages((builder) {
      builder.serve("foo", "1.1.0", pubspec: {
        "environment": {
          "sdk": ">=0.1.2 <0.2.0"
        }
      });
      builder.serve("foo", "1.2.0", pubspec: {
        "environment": {
          "sdk": ">=0.1.3 <0.2.0"
        }
      });
    });
    schedulePub(args: ["global", "activate", "foo"]);
    d.dir(
        cachePath,
        [
            d.dir(
                'global_packages',
                [
                    d.dir('foo', [d.matcherFile('pubspec.lock', contains('1.1.0'))])])]).validate();
  });
}
