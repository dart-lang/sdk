library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("responds with a 404 for a missing files in dependencies", () {
    d.dir("foo", [d.libPubspec("foo", "0.0.1")]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      })]).create();
    pubGet();
    pubServe();
    requestShould404("packages/foo/nope.dart");
    requestShould404("dir/packages/foo/nope.dart");
    endPubServe();
  });
}
