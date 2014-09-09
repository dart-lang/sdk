library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration(
      "picks up files added after serving started when using the " "native watcher",
      () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "body")])]).create();
    pubServe(args: ["--no-force-poll"]);
    waitForBuildSuccess();
    requestShouldSucceed("index.html", "body");
    d.dir(appPath, [d.dir("web", [d.file("other.html", "added")])]).create();
    waitForBuildSuccess();
    requestShouldSucceed("other.html", "added");
    endPubServe();
  });
}
