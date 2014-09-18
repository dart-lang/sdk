import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("removes binstubs when the package is deactivated", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", pubspec: {
        "executables": {
          "one": null,
          "two": null
        }
      },
          contents: [
              d.dir(
                  "bin",
                  [
                      d.file("one.dart", "main(args) => print('one');"),
                      d.file("two.dart", "main(args) => print('two');")])]);
    });
    schedulePub(args: ["global", "activate", "foo"]);
    schedulePub(args: ["global", "deactivate", "foo"]);
    d.dir(
        cachePath,
        [d.dir("bin", [d.nothing("one"), d.nothing("two")])]).validate();
  });
}
