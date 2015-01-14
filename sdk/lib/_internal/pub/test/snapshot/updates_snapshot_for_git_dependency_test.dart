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
  integration("upgrades a snapshot when a git dependency is upgraded", () {
    ensureGit();

    d.git('foo.git', [
      d.pubspec({
        "name": "foo",
        "version": "0.0.1"
      }),
      d.dir("bin", [
        d.file("hello.dart", "void main() => print('Hello!');")
      ])
    ]).create();

    d.appDir({"foo": {"git": "../foo.git"}}).create();

    pubGet(output: contains("Precompiled foo:hello."));

    d.dir(p.join(appPath, '.pub', 'bin', 'foo'), [
      d.matcherFile('hello.dart.snapshot', contains('Hello!'))
    ]).validate();

    d.git('foo.git', [
      d.dir("bin", [
        d.file("hello.dart", "void main() => print('Goodbye!');")
      ])
    ]).commit();

    pubUpgrade(output: contains("Precompiled foo:hello."));

    d.dir(p.join(appPath, '.pub', 'bin', 'foo'), [
      d.matcherFile('hello.dart.snapshot', contains('Goodbye!'))
    ]).validate();

    var process = pubRun(args: ['foo:hello']);
    process.stdout.expect("Goodbye!");
    process.shouldExit();
  });
}
