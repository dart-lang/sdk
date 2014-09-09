import 'package:path/path.dart' as path;
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration('includes dev dependencies in the results', () {
    d.dir("foo", [d.libDir("foo"), d.libPubspec("foo", "1.0.0")]).create();
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "dev_dependencies": {
          "foo": {
            "path": path.join(sandboxDir, "foo")
          }
        }
      })]).create();
    pubGet();
    schedulePub(args: ["list-package-dirs", "--format=json"], outputJson: {
      "packages": {
        "foo": path.join(sandboxDir, "foo", "lib"),
        "myapp": canonicalize(path.join(sandboxDir, appPath, "lib"))
      },
      "input_files": [
          canonicalize(path.join(sandboxDir, appPath, "pubspec.lock")),
          canonicalize(path.join(sandboxDir, appPath, "pubspec.yaml"))]
    });
  });
}
