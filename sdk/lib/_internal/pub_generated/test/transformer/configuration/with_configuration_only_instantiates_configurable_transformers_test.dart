library pub_tests;
import 'dart:convert';
import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';
final transformer = """
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';

class ConfigTransformer extends Transformer {
  final BarbackSettings settings;

  ConfigTransformer.asPlugin(this.settings);

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".json");
      transform.addOutput(
          new Asset.fromString(id, JSON.encode(settings.configuration)));
    });
  }
}

class RewriteTransformer extends Transformer {
  RewriteTransformer.asPlugin();

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".out");
      transform.addOutput(new Asset.fromString(id, "\$contents.out"));
    });
  }
}
""";
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration(
        "with configuration, only instantiates configurable " "transformers",
        () {
      var configuration = {
        "param": ["list", "of", "values"]
      };
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": [{
              "myapp/src/transformer": configuration
            }]
        }),
            d.dir("lib", [d.dir("src", [d.file("transformer.dart", transformer)])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var server = pubServe();
      requestShouldSucceed("foo.json", JSON.encode(configuration));
      requestShould404("foo.out");
      endPubServe();
    });
  });
}
