library pub_tests;
import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';
const DECLARING_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class DeclaringRewriteTransformer extends Transformer
    implements DeclaringTransformer {
  DeclaringRewriteTransformer.asPlugin();

  String get allowedExtensions => '.out';

  Future apply(Transform transform) {
    transform.logger.info('Rewriting \${transform.primaryInput.id}.');
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".final");
      transform.addOutput(new Asset.fromString(id, "\$contents.final"));
    });
  }

  Future declareOutputs(DeclaringTransform transform) {
    transform.declareOutput(transform.primaryId.changeExtension(".final"));
    return new Future.value();
  }
}
""";
main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("supports a user-defined declaring transformer", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/lazy", "myapp/src/declaring"]
        }),
            d.dir(
                "lib",
                [
                    d.dir(
                        "src",
                        [
                            d.file("lazy.dart", LAZY_TRANSFORMER),
                            d.file("declaring.dart", DECLARING_TRANSFORMER)])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();
      createLockFile('myapp', pkg: ['barback']);
      var server = pubServe();
      server.stdout.expect('Build completed successfully');
      requestShouldSucceed("foo.final", "foo.out.final");
      server.stdout.expect(
          emitsLines(
              '[Info from LazyRewrite]:\n' 'Rewriting myapp|web/foo.txt.\n'
                  '[Info from DeclaringRewrite]:\n' 'Rewriting myapp|web/foo.out.'));
      endPubServe();
    });
  });
}
