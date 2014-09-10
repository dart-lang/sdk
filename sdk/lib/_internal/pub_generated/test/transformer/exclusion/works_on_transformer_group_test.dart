library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';
const GROUP = """
import 'package:barback/barback.dart';

import 'transformer.dart';

class RewriteGroup implements TransformerGroup {
  RewriteGroup.asPlugin();

  Iterable<Iterable> get phases => [[new RewriteTransformer.asPlugin()]];
}
""";
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("works on a transformer group", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": [{
              "myapp/src/group": {
                "\$include": ["web/a.txt", "web/b.txt"],
                "\$exclude": "web/a.txt"
              }
            }]
        }),
            d.dir(
                "lib",
                [
                    d.dir(
                        "src",
                        [
                            d.file("transformer.dart", REWRITE_TRANSFORMER),
                            d.file("group.dart", GROUP)])]),
            d.dir(
                "web",
                [
                    d.file("a.txt", "a.txt"),
                    d.file("b.txt", "b.txt"),
                    d.file("c.txt", "c.txt")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      pubServe();
      requestShould404("a.out");
      requestShouldSucceed("b.out", "b.txt.out");
      requestShould404("c.out");
      endPubServe();
    });
  });
}
