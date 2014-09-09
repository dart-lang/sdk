library pub_tests;
import 'dart:io';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  if (Platform.operatingSystem == "windows") return;
  initConfig();
  integration('uses a relative symlink for the self link', () {
    d.dir(appPath, [d.appPubspec(), d.libDir('foo')]).create();
    pubGet();
    scheduleRename(appPath, "moved");
    d.dir(
        "moved",
        [
            d.dir(
                "packages",
                [d.dir("myapp", [d.file('foo.dart', 'main() => "foo";')])])]).validate();
  });
  integration('uses a relative symlink for secondary packages directory', () {
    d.dir(appPath, [d.appPubspec(), d.libDir('foo'), d.dir("bin")]).create();
    pubGet();
    scheduleRename(appPath, "moved");
    d.dir(
        "moved",
        [
            d.dir(
                "bin",
                [
                    d.dir(
                        "packages",
                        [d.dir("myapp", [d.file('foo.dart', 'main() => "foo";')])])])]).validate();
  });
}
