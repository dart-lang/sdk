library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("supports a user-defined lazy transformer", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
            d.dir("lib", [d.dir("src", [d.file("transformer.dart", LAZY_TRANSFORMER)])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var server = pubServe();
      server.stdout.expect('Build completed successfully');
      requestShouldSucceed("foo.out", "foo.out");
      server.stdout.expect(
          emitsLines('[Info from LazyRewrite]:\n' 'Rewriting myapp|web/foo.txt.'));
      endPubServe();
    });
  });
}
