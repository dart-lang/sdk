library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';
main() {
  initConfig();
  integration("unbinds a directory from a port", () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir("test", [d.file("index.html", "<test body>")]),
            d.dir("web", [d.file("index.html", "<body>")])]).create();
    pubServe();
    requestShouldSucceed("index.html", "<body>");
    requestShouldSucceed("index.html", "<test body>", root: "test");
    expectWebSocketResult("unserveDirectory", {
      "path": "test"
    }, {
      "url": getServerUrl("test")
    });
    requestShouldNotConnect("index.html", root: "test");
    requestShouldSucceed("index.html", "<body>");
    endPubServe();
  });
}
