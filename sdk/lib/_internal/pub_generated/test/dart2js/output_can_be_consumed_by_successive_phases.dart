// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

/// The code for a transformer that renames ".js" files to ".out".
const JS_REWRITE_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class RewriteTransformer extends Transformer {
  RewriteTransformer.asPlugin();

  String get allowedExtensions => '.js';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".out");
      transform.addOutput(new Asset.fromString(id, contents));
    });
  }
}
""";

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("output can be consumed by successive phases", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["\$dart2js", "myapp/src/transformer"]
        }),
            d.dir(
                "lib",
                [d.dir("src", [d.file("transformer.dart", JS_REWRITE_TRANSFORMER)])]),
            d.dir("web", [d.file("main.dart", "void main() {}")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      pubServe();
      requestShouldSucceed("main.dart.out", isUnminifiedDart2JSOutput);
      endPubServe();
    });
  });
}
