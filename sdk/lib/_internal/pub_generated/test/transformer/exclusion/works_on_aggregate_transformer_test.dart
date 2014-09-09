library pub_tests;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';
const AGGREGATE_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';
import 'package:path/path.dart' as p;

class ManyToOneTransformer extends AggregateTransformer {
  ManyToOneTransformer.asPlugin();

  String classifyPrimary(AssetId id) {
    if (id.extension != '.txt') return null;
    return p.url.dirname(id.path);
  }

  Future apply(AggregateTransform transform) {
    return transform.primaryInputs.toList().then((assets) {
      assets.sort((asset1, asset2) => asset1.id.path.compareTo(asset2.id.path));
      return Future.wait(assets.map((asset) => asset.readAsString()));
    }).then((contents) {
      var id = new AssetId(transform.package,
          p.url.join(transform.key, 'out.txt'));
      transform.addOutput(new Asset.fromString(id, contents.join('\\n')));
    });
  }
}
""";
main() {
  initConfig();
  withBarbackVersions(">=0.14.1", () {
    integration("works on an aggregate transformer", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": [{
              "myapp": {
                "\$include": ["web/a.txt", "web/b.txt", "web/c.txt"],
                "\$exclude": "web/a.txt"
              }
            }]
        }),
            d.dir("lib", [d.file("transformer.dart", AGGREGATE_TRANSFORMER)]),
            d.dir(
                "web",
                [
                    d.file("a.txt", "a"),
                    d.file("b.txt", "b"),
                    d.file("c.txt", "c"),
                    d.file("d.txt", "d")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      pubServe();
      requestShouldSucceed("out.txt", "b\nc");
      endPubServe();
    });
  });
}
