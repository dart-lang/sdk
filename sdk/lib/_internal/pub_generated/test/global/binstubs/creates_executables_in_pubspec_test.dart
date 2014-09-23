import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("creates binstubs for each executable in the pubspec", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", pubspec: {
        "executables": {
          "one": null,
          "two-renamed": "second"
        }
      },
          contents: [
              d.dir(
                  "bin",
                  [
                      d.file("one.dart", "main(args) => print('one');"),
                      d.file("second.dart", "main(args) => print('two');"),
                      d.file("nope.dart", "main(args) => print('nope');")])]);
    });
    schedulePub(
        args: ["global", "activate", "foo"],
        output: contains("Installed executables one and two-renamed."));
    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [
                    d.matcherFile("one", contains("one")),
                    d.matcherFile("two-renamed", contains("second")),
                    d.nothing("two"),
                    d.nothing("nope")])]).validate();
  });
}
