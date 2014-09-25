import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("warns if the binstub directory is not on the path", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", pubspec: {
        "executables": {
          "some-dart-script": "script"
        }
      },
          contents: [
              d.dir("bin", [d.file("script.dart", "main(args) => print('ok \$args');")])]);
    });
    schedulePub(
        args: ["global", "activate", "foo"],
        error: contains("is not on your path"));
  });
}
