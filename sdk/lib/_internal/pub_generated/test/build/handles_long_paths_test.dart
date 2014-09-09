import 'package:scheduled_test/scheduled_test.dart';
import 'package:path/path.dart' as path;
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("handles long relative paths", () {
    currentSchedule.timeout *= 3;
    d.dir(
        "some_long_dependency_name",
        [
            d.libPubspec("foo", "0.0.1"),
            d.dir("lib", [d.file("foo.txt", "foo")])]).create();
    var longPath = "";
    for (var i = 0; i < 100; i++) {
      longPath = path.join(longPath, "..", "some_long_dependency_name");
    }
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": longPath
        }
      }), d.dir("web", [d.file("index.html", "html")])]).create();
    schedulePub(
        args: ["build"],
        output: new RegExp(r'Built 2 files to "build".'));
    d.dir(
        appPath,
        [
            d.dir(
                'build',
                [
                    d.dir(
                        'web',
                        [
                            d.file("index.html", "html"),
                            d.dir('packages', [d.dir('foo', [d.file('foo.txt', 'foo')])])])])]).validate();
  });
}
