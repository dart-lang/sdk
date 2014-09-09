library pub_tests;
import 'dart:convert';
import 'package:scheduled_test/scheduled_stream.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
final transformer = """
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';

class GetInputTransformer extends Transformer {
  GetInputTransformer.asPlugin();

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    return transform.readInputAsString(new AssetId('myapp', 'nonexistent'))
        .catchError((error) {
      if (error is! AssetNotFoundException) throw error;
      transform.addOutput(new Asset.fromString(transform.primaryInput.id,
          JSON.encode({
        'package': error.id.package,
        'path': error.id.path
      })));
    });
  }
}
""";
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("AssetNotFoundExceptions are detectable", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
            d.dir("lib", [d.dir("src", [d.file("transformer.dart", transformer)])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var server = pubServe();
      requestShouldSucceed("foo.txt", JSON.encode({
        "package": "myapp",
        "path": "nonexistent"
      }));
      endPubServe();
      server.stderr.expect(isDone);
    });
  });
}
