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
  integration("creates a snapshot for an immediate dependency's executables",
      () {
    servePackages((builder) {
      builder.serve("foo", "1.2.3", contents: [
        d.dir("bin", [
          d.file("hello.dart", "void main() => print('hello!');"),
          d.file("goodbye.dart", "void main() => print('goodbye!');"),
          d.file("shell.sh", "echo shell"),
          d.dir("subdir", [
            d.file("sub.dart", "void main() => print('sub!');")
          ])
        ])
      ]);
    });

    d.appDir({"foo": "1.2.3"}).create();

    pubGet(output: allOf([
      contains("Precompiled foo:hello."),
      contains("Precompiled foo:goodbye.")
    ]));

    d.dir(p.join(appPath, '.pub', 'bin'), [
      d.file('sdk-version', '0.1.2+3\n'),
      d.dir('foo', [
        d.matcherFile('hello.dart.snapshot', contains('hello!')),
        d.matcherFile('goodbye.dart.snapshot', contains('goodbye!')),
        d.nothing('shell.sh.snapshot'),
        d.nothing('subdir')
      ])
    ]).validate();

    var process = pubRun(args: ['foo:hello']);
    process.stdout.expect("hello!");
    process.shouldExit();

    process = pubRun(args: ['foo:goodbye']);
    process.stdout.expect("goodbye!");
    process.shouldExit();
  });
}
