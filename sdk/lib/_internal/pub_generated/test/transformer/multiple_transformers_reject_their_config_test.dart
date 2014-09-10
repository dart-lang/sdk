library pub_tests;
import 'package:scheduled_test/scheduled_stream.dart';
import 'package:scheduled_test/scheduled_test.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';
const REJECT_CONFIG_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class RejectConfigTransformer extends Transformer {
  RejectConfigTransformer.asPlugin(BarbackSettings settings) {
    throw "I hate these settings!";
  }

  Future<bool> isPrimary(_) => new Future.value(true);
  Future apply(Transform transform) {}
}
""";
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration(
        "multiple transformers in the same phase reject their " "configurations",
        () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": [[{
                "myapp/src/transformer": {
                  'foo': 'bar'
                }
              }, {
                "myapp/src/transformer": {
                  'baz': 'bang'
                }
              }, {
                "myapp/src/transformer": {
                  'qux': 'fblthp'
                }
              }]]
        }),
            d.dir(
                "lib",
                [
                    d.dir(
                        "src",
                        [d.file("transformer.dart", REJECT_CONFIG_TRANSFORMER)])])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var pub = startPubServe();
      for (var i = 0; i < 3; i++) {
        pub.stderr.expect(
            consumeThrough(
                endsWith('Error loading transformer: ' 'I hate these settings!')));
      }
      pub.shouldExit(1);
    });
  });
}
