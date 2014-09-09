import 'package:path/path.dart' as path;
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("uses what's in the lockfile regardless of the pubspec", () {
    d.dir("foo", [d.libDir("foo"), d.libPubspec("foo", "1.0.0")]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": path.join(sandboxDir, "foo")
        }
      })]).create();
    pubGet();
    d.dir(appPath, [d.appPubspec({
        "bar": "any"
      })]).create();
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
