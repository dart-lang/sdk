library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration(
      "watches modifications to files when using the native watcher",
      () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "before")])]).create();
    pubServe(args: ["--no-force-poll"]);
    requestShouldSucceed("index.html", "before");
    d.dir(appPath, [d.dir("web", [d.file("index.html", "after")])]).create();
    waitForBuildSuccess();
    requestShouldSucceed("index.html", "after");
    endPubServe();
  });
}
