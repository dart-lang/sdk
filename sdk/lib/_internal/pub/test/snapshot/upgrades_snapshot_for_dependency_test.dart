// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("upgrades a snapshot when a dependency is upgraded", () {
    servePackages([
      packageMap("foo", "1.2.3", {"bar": "any"}),
      packageMap("bar", "1.2.3")
    ], contents: [
      d.dir("lib", [d.file("bar.dart", "final message = 'hello!';")]),
      d.dir("bin", [
        d.file("hello.dart", """
import 'package:bar/bar.dart';

void main() => print(message);
""")
      ])
    ]);

    d.appDir({"foo": "any"}).create();

    pubGet(output: contains("Precompiled foo:hello."));

    d.dir(p.join(appPath, '.pub', 'bin', 'foo'), [
      d.matcherFile('hello.dart.snapshot', contains('hello!'))
    ]).validate();

    servePackages([
      packageMap("foo", "1.2.3", {"bar": "any"}),
      packageMap("bar", "1.2.4")
    ], contents: [
      d.dir("lib", [d.file("bar.dart", "final message = 'hello 2!';")]),
    ], replace: true);

    pubUpgrade(output: contains("Precompiled foo:hello."));

    d.dir(p.join(appPath, '.pub', 'bin', 'foo'), [
      d.matcherFile('hello.dart.snapshot', contains('hello 2!'))
    ]).validate();

    var process = pubRun(args: ['foo:hello']);
    process.stdout.expect("hello 2!");
    process.shouldExit();
  });
}
