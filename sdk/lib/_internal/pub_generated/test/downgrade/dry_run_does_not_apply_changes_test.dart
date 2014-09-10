import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("--dry-run shows report but does not apply changes", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "2.0.0");
    });
    d.appDir({
      "foo": "2.0.0"
    }).create();
    pubGet();
    d.appDir({
      "foo": "any"
    }).create();
    schedule(() {
      deleteEntry(path.join(sandboxDir, appPath, "packages"));
    });
    pubDowngrade(
        args: ["--dry-run"],
        output: allOf(
            [contains("< foo 1.0.0"), contains("Would change 1 dependency.")]));
    d.dir(
        appPath,
        [
            d.matcherFile("pubspec.lock", contains("2.0.0")),
            d.nothing("packages")]).validate();
  });
}
