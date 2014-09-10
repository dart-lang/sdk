import 'package:path/path.dart' as path;
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration('prints the local paths to all packages in the lockfile', () {
    servePackages((builder) => builder.serve("bar", "1.0.0"));
    d.dir("foo", [d.libDir("foo"), d.libPubspec("foo", "1.0.0")]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": path.join(sandboxDir, "foo")
        },
        "bar": "any"
      })]).create();
    pubGet();
    schedulePub(args: ["list-package-dirs", "--format=json"], outputJson: {
      "packages": {
        "foo": path.join(sandboxDir, "foo", "lib"),
        "bar": port.then(
            (p) =>
                path.join(
                    sandboxDir,
                    cachePath,
                    "hosted",
                    "localhost%58$p",
                    "bar-1.0.0",
                    "lib")),
        "myapp": canonicalize(path.join(sandboxDir, appPath, "lib"))
      },
      "input_files": [
          canonicalize(path.join(sandboxDir, appPath, "pubspec.lock")),
          canonicalize(path.join(sandboxDir, appPath, "pubspec.yaml"))]
    });
  });
}
