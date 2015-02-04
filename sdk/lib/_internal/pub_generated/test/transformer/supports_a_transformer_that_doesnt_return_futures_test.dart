// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

const TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class RewriteTransformer extends Transformer implements DeclaringTransformer {
  RewriteTransformer.asPlugin();

  bool isPrimary(AssetId id) => id.extension == '.txt';

  void apply(Transform transform) {
    transform.addOutput(new Asset.fromString(
        transform.primaryInput.id, "new contents"));
  }

  void declareOutputs(DeclaringTransform transform) {
    transform.declareOutput(transform.primaryId);
  }
}
""";

main() {
  initConfig();
  withBarbackVersions("any", () {
    integration("supports a transformer that doesn't return futures", () {
      d.dir(appPath, [d.pubspec({
          "name": "myapp",
          "transformers": ["myapp/src/transformer"]
        }),
            d.dir("lib", [d.dir("src", [d.file("transformer.dart", TRANSFORMER)])]),
            d.dir("web", [d.file("foo.txt", "foo")])]).create();

      createLockFile('myapp', pkg: ['barback']);

      pubServe();
      requestShouldSucceed("foo.txt", "new contents");
      endPubServe();
    });
  });
}
