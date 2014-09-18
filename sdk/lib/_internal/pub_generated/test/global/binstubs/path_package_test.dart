import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("creates binstubs when activating a path package", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "foo": null
        }
      }),
          d.dir("bin", [d.file("foo.dart", "main() => print('ok');")])]).create();
    schedulePub(
        args: ["global", "activate", "--source", "path", "../foo"],
        output: contains("Installed executable foo."));
    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [d.matcherFile("foo", contains("pub global run foo:foo"))])]).validate();
  });
}
