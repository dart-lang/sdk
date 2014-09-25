import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("the binstubs runs a precompiled snapshot if present", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", pubspec: {
        "executables": {
          "foo-script": "script"
        }
      },
          contents: [
              d.dir("bin", [d.file("script.dart", "main(args) => print('ok');")])]);
    });
    schedulePub(args: ["global", "activate", "foo"]);
    d.dir(
        cachePath,
        [
            d.dir(
                "bin",
                [
                    d.matcherFile(
                        binStubName("foo-script"),
                        contains("script.dart.snapshot"))])]).validate();
  });
}
