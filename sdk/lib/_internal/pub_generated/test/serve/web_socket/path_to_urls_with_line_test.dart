library pub_tests;
import 'package:path/path.dart' as p;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';
main() {
  initConfig();
  integration("pathToUrls provides output line if given source", () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("main.dart", "main")])]).create();
    pubServe();
    expectWebSocketResult("pathToUrls", {
      "path": p.join("web", "main.dart"),
      "line": 12345
    }, {
      "urls": [getServerUrl("web", "main.dart")],
      "line": 12345
    });
    endPubServe();
  });
}
