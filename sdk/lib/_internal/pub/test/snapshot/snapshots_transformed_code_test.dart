// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

const REPLACE_TRANSFORMER = """
import 'dart:async';

import 'package:barback/barback.dart';

class ReplaceTransformer extends Transformer {
  ReplaceTransformer.asPlugin();

  String get allowedExtensions => '.dart';

  Future apply(Transform transform) {
    return transform.primaryInput.readAsString().then((contents) {
      transform.addOutput(new Asset.fromString(transform.primaryInput.id,
          contents.replaceAll("REPLACE ME", "hello!")));
    });
  }
}
""";

main() {
  initConfig();
  integration("snapshots the transformed version of an executable", () {
    servePackages([
      packageMap("foo", "1.2.3", {"barback": "any"})
          ..addAll({'transformers': ['foo']})
    ], contents: [
      d.dir("lib", [d.file("foo.dart", REPLACE_TRANSFORMER)]),
      d.dir("bin", [
        d.file("hello.dart", """
final message = 'REPLACE ME';

void main() => print(message);
"""),
      ])
    ], serveBarback: true);

    d.appDir({"foo": "1.2.3"}).create();

    pubGet(output: contains("Precompiled foo:hello."));

    d.dir(p.join(appPath, '.pub', 'bin'), [
      d.dir('foo', [d.matcherFile('hello.dart.snapshot', contains('hello!'))])
    ]).validate();

    var process = pubRun(args: ['foo:hello']);
    process.stdout.expect("hello!");
    process.shouldExit();
  });
}
