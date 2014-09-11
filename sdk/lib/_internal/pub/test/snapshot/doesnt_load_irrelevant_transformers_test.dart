// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

const BROKEN_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class BrokenTransformer extends Transformer {
  BrokenTransformer.asPlugin();

  // This file intentionally has a syntax error so that any attempt to load it
  // will crash.
""";

main() {
  initConfig();

  // Regression test for issue 20917.
  integration("snapshots the transformed version of an executable", () {
    servePackages((builder) {
      builder.serveRepoPackage('barback');

      builder.serve("foo", "1.2.3",
          contents: [
        d.dir("bin", [
          d.file("hello.dart", "void main() => print('hello!');")
        ])
      ]);
    });

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": "1.2.3",
          "barback": "any"
        },
        "transformers": ["myapp"]
      }),
      d.dir("lib", [
        d.file("transformer.dart", BROKEN_TRANSFORMER)
      ])
    ]).create();

    pubGet(output: contains("Precompiled foo:hello."));

    d.dir(p.join(appPath, '.pub', 'bin'), [
      d.dir('foo', [d.matcherFile('hello.dart.snapshot', contains('hello!'))])
    ]).validate();

    var process = pubRun(args: ['foo:hello']);
    process.stdout.expect("hello!");
    process.shouldExit();
  });
}
