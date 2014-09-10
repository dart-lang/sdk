import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration('preview shows an error if the package is private', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["publish_to"] = "http://example.com";
    d.dir(appPath, [d.pubspec(pkg)]).create();
    schedulePub(
        args: ["lish", "--dry-run"],
        output: contains("Publishing test_pkg 1.0.0 to http://example.com"));
  });
}
