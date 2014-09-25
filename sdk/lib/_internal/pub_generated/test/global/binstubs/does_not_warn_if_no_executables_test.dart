import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
main() {
  initConfig();
  integration("does not warn if the package has no executables", () {
    servePackages((builder) {
      builder.serve(
          "foo",
          "1.0.0",
          contents: [
              d.dir("bin", [d.file("script.dart", "main(args) => print('ok \$args');")])]);
    });
    schedulePub(
        args: ["global", "activate", "foo"],
        output: isNot(contains("is not on your path")));
  });
}
