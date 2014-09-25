import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("only creates binstubs for the listed executables", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "one": "script",
          "two": "script",
          "three": "script"
        }
      }),
          d.dir("bin", [d.file("script.dart", "main() => print('ok');")])]).create();
    schedulePub(
        args: [
            "global",
            "activate",
            "--source",
            "path",
            "../foo",
            "-x",
            "one",
            "--executable",
            "three"],
        output: contains("Installed executables one and three."));
    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [
                    d.matcherFile(binStubName("one"), contains("pub global run foo:script")),
                    d.nothing(binStubName("two")),
                    d.matcherFile(
                        binStubName("three"),
                        contains("pub global run foo:script"))])]).validate();
  });
}
