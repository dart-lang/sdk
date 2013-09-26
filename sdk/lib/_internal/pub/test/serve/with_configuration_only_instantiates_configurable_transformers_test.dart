// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:convert';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

final transformer = """
import 'dart:async';
import 'dart:convert';

import 'package:barback/barback.dart';

class ConfigTransformer extends Transformer {
  final Map configuration;

  ConfigTransformer.asPlugin(this.configuration);

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      var id = transform.primaryInput.id.changeExtension(".json");
      transform.addOutput(new Asset.fromString(id, JSON.encode(configuration)));
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
  integration("with configuration, only instantiates configurable transformers",
      () {
    var configuration = {"param": ["list", "of", "values"]};

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": [{"myapp/src/transformer": configuration}]
      }),
      d.dir("lib", [d.dir("src", [
        d.file("transformer.dart", transformer)
      ])]),
      d.dir("web", [
        d.file("foo.txt", "foo")
      ])
    ]).create();

    createLockFile('myapp', pkg: ['barback']);

    var server = startPubServe();
    requestShouldSucceed("foo.json", JSON.encode(configuration));
    requestShould404("foo.out");
    endPubServe();
  });
}
