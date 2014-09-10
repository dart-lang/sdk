library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';
main() {
  initConfig();
  integration("exits when the connection closes", () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "<body>")])]).create();
    var server = pubServe();
    expectWebSocketResult("urlToAssetId", {
      "url": getServerUrl("web", "index.html")
    }, {
      "package": "myapp",
      "path": "web/index.html"
    });
    expectWebSocketResult("exitOnClose", null, null);
    closeWebSocket();
    server.stdout.expect("Build completed successfully");
    server.stdout.expect("WebSocket connection closed, terminating.");
    server.shouldExit(0);
  });
}
