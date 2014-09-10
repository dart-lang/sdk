import 'dart:io';
import 'package:path/path.dart' as path;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  if (Platform.operatingSystem == "windows") return;
  initConfig();
  integration(
      "generates a symlink with a relative path if the dependency "
          "path was relative",
      () {
    d.dir("foo", [d.libDir("foo"), d.libPubspec("foo", "0.0.1")]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      })]).create();
    pubGet();
    d.dir("moved").create();
    scheduleRename("foo", path.join("moved", "foo"));
    scheduleRename(appPath, path.join("moved", appPath));
    d.dir(
        "moved",
        [
            d.dir(
                packagesPath,
                [d.dir("foo", [d.file("foo.dart", 'main() => "foo";')])])]).validate();
  });
}
