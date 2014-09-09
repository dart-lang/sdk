library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  integration("responds with a 404 on incomplete special URLs", () {
    d.dir("foo", [d.libPubspec("foo", "0.0.1")]).create();
    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      }),
          d.dir("lib", [d.file("packages")]),
          d.dir("web", [d.file("packages")])]).create();
    pubGet();
    pubServe();
    requestShould404("packages");
    requestShould404("packages/");
    requestShould404("packages/myapp");
    requestShould404("packages/myapp/");
    requestShould404("packages/foo");
    requestShould404("packages/foo/");
    requestShould404("packages/unknown");
    requestShould404("packages/unknown/");
    endPubServe();
  });
}
