import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("the binstubs runs pub global run if there is no snapshot", () {
    d.dir("foo", [d.pubspec({
        "name": "foo",
        "executables": {
          "foo-script": "script"
        }
      }),
          d.dir("bin", [d.file("script.dart", "main() => print('ok');")])]).create();
    schedulePub(
        args: ["global", "activate", "--source", "path", "../foo"],
        output: contains("Installed executable foo-script."));
    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [
                    d.matcherFile(
                        binStubName("foo-script"),
                        contains("pub global run foo:script"))])]).validate();
  });
}
