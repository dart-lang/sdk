library pub_tests;
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("responds with a 404 for missing source files", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir("lib", [d.file("nope.dart", "nope")]),
            d.dir("web", [d.file("index.html", "<body>")])]).create();
    pubServe();
    schedule(() {
      deleteEntry(path.join(sandboxDir, appPath, "lib", "nope.dart"));
      deleteEntry(path.join(sandboxDir, appPath, "web", "index.html"));
    }, "delete files");
    requestShould404("index.html");
    requestShould404("packages/myapp/nope.dart");
    requestShould404("dir/packages/myapp/nope.dart");
    endPubServe();
  });
}
