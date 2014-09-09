import 'package:path/path.dart' as path;
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("reports a missing pubspec error using JSON", () {
    d.dir(appPath).create();
    schedulePub(args: ["list-package-dirs", "--format=json"], outputJson: {
      "error": 'Could not find a file named "pubspec.yaml" in "'
          '${canonicalize(path.join(sandboxDir, appPath))}".',
      "path": canonicalize(path.join(sandboxDir, appPath, "pubspec.yaml"))
    }, exitCode: 1);
  });
}
