// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
                [d.dir("src", [// Include a lazy transformer before the declaring transformer,
            // because otherwise its behavior is indistinguishable from a normal
            // transformer.
            d.file("lazy.dart", LAZY_TRANSFORMER),
                d.file("declaring.dart", DECLARING_TRANSFORMER)])]),
                d.dir("web", [d.file("foo.txt", "foo")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      var server = pubServe();
      // The build should complete without either transformer logging anything.
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
