library pub_tests;
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("works on a lazy transformer", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": [{
              "myapp": {
                "\$include": ["web/a.txt", "web/b.txt"],
                "\$exclude": "web/a.txt"
              }
            }]
        }),
            d.dir("lib", [d.file("transformer.dart", LAZY_TRANSFORMER)]),
            d.dir(
                "web",
                [d.file("a.txt", "a"), d.file("b.txt", "b"), d.file("c.txt", "c")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var server = pubServe();
      server.stdout.expect("Build completed successfully");
      requestShould404("a.out");
      requestShouldSucceed("b.out", isNot(isEmpty));
      server.stdout.expect(
          consumeThrough(
              emitsLines("[Info from LazyRewrite]:\n" "Rewriting myapp|web/b.txt.")));
      server.stdout.expect(consumeThrough("Build completed successfully"));
      requestShould404("c.out");
      endPubServe();
    });
  });
}
