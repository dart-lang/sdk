import 'package:path/path.dart' as path;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration(
      "generates a symlink with an absolute path if the dependency "
          "path was absolute",
      () {
    d.dir("foo", [d.libDir("foo"), d.libPubspec("foo", "0.0.1")]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": path.join(sandboxDir, "foo")
        }
      })]).create();
    pubGet();
    d.dir("moved").create();
    scheduleRename(appPath, path.join("moved", appPath));
    d.dir(
        "moved",
        [
            d.dir(
                packagesPath,
                [d.dir("foo", [d.file("foo.dart", 'main() => "foo";')])])]).validate();
  });
}
