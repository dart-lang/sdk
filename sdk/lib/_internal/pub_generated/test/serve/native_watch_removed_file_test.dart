library pub_tests;
import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration(
      "stop serving a file that is removed when using the native " "watcher",
      () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "body")])]).create();
    pubServe(args: ["--no-force-poll"]);
    requestShouldSucceed("index.html", "body");
    schedule(
        () => deleteEntry(path.join(sandboxDir, appPath, "web", "index.html")));
    waitForBuildSuccess();
    requestShould404("index.html");
    endPubServe();
  });
}
