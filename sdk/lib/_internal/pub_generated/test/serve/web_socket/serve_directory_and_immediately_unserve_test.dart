library pub_tests;
import 'dart:async';
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';
main() {
  initConfig();
  integration(
      "binds a directory to a new port and immediately unbinds that " "directory",
      () {
    d.dir(
        appPath,
        [
            d.appPubspec(),
            d.dir("test", [d.file("index.html", "<test body>")]),
            d.dir("web", [d.file("index.html", "<body>")])]).create();
    pubServe(args: ["web"]);
    var serveRequest = webSocketRequest("serveDirectory", {
      "path": "test"
    });
    var unserveRequest = webSocketRequest("unserveDirectory", {
      "path": "test"
    });
    schedule(() {
      return Future.wait([serveRequest, unserveRequest]).then((results) {
        expect(results[0], contains("result"));
        expect(results[1], contains("result"));
        expect(results[0]["result"]["url"], matches(r"http://localhost:\d+"));
        expect(results[0]["result"], equals(results[1]["result"]));
      });
    });
    endPubServe();
  });
}
