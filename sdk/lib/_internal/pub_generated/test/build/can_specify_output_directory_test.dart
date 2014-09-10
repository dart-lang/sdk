library pub_tests;
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
main() {
  initConfig();
  integration("can specify the output directory to build into", () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir('web', [d.file('file.txt', 'web')])]).create();
    var outDir = path.join("out", "dir");
    schedulePub(
        args: ["build", "-o", outDir],
        output: contains('Built 1 file to "$outDir".'));
    d.dir(
        appPath,
        [
            d.dir(
                "out",
                [d.dir("dir", [d.dir("web", [d.file("file.txt", "web")])])])]).validate();
  });
}
