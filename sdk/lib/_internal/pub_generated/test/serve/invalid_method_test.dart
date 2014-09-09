library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("responds with a 405 for an invalid method", () {
    d.dir(
        appPath,
        [d.appPubspec(), d.dir("web", [d.file("index.html", "<body>")])]).create();
    pubServe();
    postShould405("index.html");
    endPubServe();
  });
}
