// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';

final transformer = """
import 'dart:async';

import 'package:barback/barback.dart';

class ModeTransformer extends Transformer {
  final BarbackSettings settings;

  ModeTransformer.asPlugin(this.settings);

  String get allowedExtensions => '.txt';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      transform.addOutput(
          new Asset.fromString(transform.primaryInput.id, settings.mode.name));
    });
  }
}
""";

main() {
  initConfig();
  integration("mode defaults to 'release' in pub build", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": ["myapp/src/transformer"]
      }),
      d.dir("lib", [d.dir("src", [
        d.file("transformer.dart", transformer)
      ])]),
      d.dir("web", [
        d.file("foo.txt", "foo")
      ])
    ]).create();

    createLockFile('myapp', pkg: ['barback']);

    schedulePub(args: ["build"],
        output: new RegExp(r"Built 1 file!"));

    d.dir(appPath, [
      d.dir('build', [
        d.dir('web', [
          d.file('foo.txt', 'release')
        ])
      ])
    ]).validate();
  });
}
