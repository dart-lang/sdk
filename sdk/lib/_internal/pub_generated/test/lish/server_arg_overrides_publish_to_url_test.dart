import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration('an explicit --server argument overrides a "publish_to" url', () {
    var pkg = packageMap("test_pkg", "1.0.0");
    pkg["publish_to"] = "http://pubspec.com";
    d.dir(appPath, [d.pubspec(pkg)]).create();
    schedulePub(
        args: ["lish", "--dry-run", "--server", "http://arg.com"],
        output: contains("http://arg.com"));
  });
}
