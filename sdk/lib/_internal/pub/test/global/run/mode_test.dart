// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

const TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class DartTransformer extends Transformer {
  final BarbackSettings _settings;

  DartTransformer.asPlugin(this._settings);

  String get allowedExtensions => '.in';

  void apply(Transform transform) {
    transform.addOutput(new Asset.fromString(
        new AssetId(transform.primaryInput.id.package, "bin/script.dart"),
        "void main() => print('\${_settings.mode.name}');"));
  }
}
""";

main() {
  initConfig();
  integration('runs a script in an activated package with customizable modes',
      () {
    servePackages((builder) {
      builder.serveRepoPackage("barback");

      builder.serve("foo", "1.0.0",
          deps: {"barback": "any"},
          pubspec: {"transformers": ["foo/src/transformer"]},
          contents: [
        d.dir("lib", [d.dir("src", [
          d.file("transformer.dart", TRANSFORMER),
          d.file("primary.in", "")
        ])])
      ]);
    });

    schedulePub(args: ["global", "activate", "foo"]);

    // By default it should run in release mode.
    var pub = pubRun(global: true, args: ["foo:script"]);
    pub.stdout.expect("release");
    pub.shouldExit();

    // A custom mode should be specifiable.
    pub = pubRun(global: true, args: ["--mode", "custom-mode", "foo:script"]);
    pub.stdout.expect("custom-mode");
    pub.shouldExit();
  });
}
