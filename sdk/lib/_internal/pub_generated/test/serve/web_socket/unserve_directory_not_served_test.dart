library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';
main() {
  initConfig();
  integration("errors if the directory is not served", () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "<body>")])]).create();
    pubServe();
    expectWebSocketError("unserveDirectory", {
      "path": "test"
    }, NOT_SERVED, 'Directory "test" is not bound to a server.');
    endPubServe();
  });
}
