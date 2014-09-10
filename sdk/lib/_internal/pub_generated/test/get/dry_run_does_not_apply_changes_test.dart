import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("--dry-run shows but does not apply changes", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
    });
    d.appDir({
      "foo": "1.0.0"
    }).create();
    pubGet(
        args: ["--dry-run"],
        output: allOf(
            [contains("+ foo 1.0.0"), contains("Would change 1 dependency.")]));
    d.dir(
        appPath,
        [d.nothing("pubspec.lock"), d.nothing("packages")]).validate();
  });
}
