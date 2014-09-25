import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("does not warn if the binstub directory is on the path", () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0", pubspec: {
        "executables": {
          "script": null
        }
      },
          contents: [
              d.dir("bin", [d.file("script.dart", "main(args) => print('ok \$args');")])]);
    });
    var binDir = p.dirname(Platform.executable);
    var separator = Platform.operatingSystem == "windows" ? ";" : ":";
    var path = "${Platform.environment["PATH"]}$separator$binDir";
    schedulePub(
        args: ["global", "activate", "foo"],
        output: isNot(contains("is not on your path")),
        environment: {
      "PATH": path
    });
  });
}
