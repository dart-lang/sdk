library pub_tests;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/scheduled_stream.dart';
import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';
const SOURCE_MAPS_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';
import 'package:source_maps/source_maps.dart';

class RewriteTransformer extends Transformer {
  RewriteTransformer.asPlugin();

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    transform.logger.info('info!');
    transform.logger.warning('Warning!',
        asset: transform.primaryInput.id.changeExtension('.foo'));
    var sourceFile = new SourceFile.text(
        'http://fake.com/not_real.dart',
        'not a real\\ndart file');
    transform.logger.error('ERROR!', span: new FileSpan(sourceFile, 11));
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".out");
      transform.addOutput(new Asset.fromString(id, "\$contents.out"));
    });
  }
}
""";
const SOURCE_SPAN_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';
import 'package:source_span/source_span.dart';

class RewriteTransformer extends Transformer {
  RewriteTransformer.asPlugin();

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    transform.logger.info('info!');
    transform.logger.warning('Warning!',
        asset: transform.primaryInput.id.changeExtension('.foo'));
    var sourceFile = new SourceFile('not a real\\ndart file',
        url: 'http://fake.com/not_real.dart');
    transform.logger.error('ERROR!', span: sourceFile.span(11, 12));
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".out");
      transform.addOutput(new Asset.fromString(id, "\$contents.out"));
    });
  }
}
""";
main() {
  initConfig();
  withBarbackVersions("<0.15.0", () => runTest(SOURCE_MAPS_TRANSFORMER));
  withBarbackVersions(">=0.14.2", () => runTest(SOURCE_SPAN_TRANSFORMER));
}
void runTest(String transformerText) {
  integration("can log messages", () {
    d.dir(appPath, [d.pubspec({
        "name": "myapp",
        "transformers": ["myapp/src/transformer"]
      }),
          d.dir("lib", [d.dir("src", [d.file("transformer.dart", transformerText)])]),
          d.dir("web", [d.file("foo.txt", "foo")])]).create();
    createLockFile('myapp', pkg: ['barback']);
    var pub = startPub(args: ["build"]);
    pub.stdout.expect(startsWith("Loading source assets..."));
    pub.stdout.expect(consumeWhile(matches("Loading .* transformers...")));
    pub.stdout.expect(startsWith("Building myapp..."));
    pub.stdout.expect(emitsLines("""
[Rewrite on myapp|web/foo.txt]:
info!"""));
    pub.stderr.expect(emitsLines("""
[Rewrite on myapp|web/foo.txt with input myapp|web/foo.foo]:
Warning!
[Rewrite on myapp|web/foo.txt]:"""));
    pub.stderr.expect(
        allOf(
            [
                contains("2"),
                contains("1"),
                contains("http://fake.com/not_real.dart"),
                contains("ERROR")]));
    pub.stderr.expect(allow(inOrder(["d", "^"])));
    pub.stderr.expect("Build failed.");
    pub.shouldExit(exit_codes.DATA);
  });
}
