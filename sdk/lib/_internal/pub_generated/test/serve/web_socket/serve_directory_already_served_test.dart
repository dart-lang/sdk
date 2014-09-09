library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';
main() {
  initConfig();
  integration("returns the old URL if the directory is already served", () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "<body>")])]).create();
    pubServe();
    expectWebSocketResult("serveDirectory", {
      "path": "web"
    }, {
      "url": getServerUrl("web")
    });
    endPubServe();
  });
}
