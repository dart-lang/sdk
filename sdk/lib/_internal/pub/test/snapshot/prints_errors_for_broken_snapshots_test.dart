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
  integration("prints errors for broken snapshot compilation", () {
    servePackages([
      packageMap("foo", "1.2.3"),
      packageMap("bar", "1.2.3")
    ], contents: [
      d.dir("bin", [
        d.file("hello.dart", "void main() { no closing brace"),
        d.file("goodbye.dart", "void main() { no closing brace"),
      ])
    ]);

    d.appDir({"foo": "1.2.3", "bar": "1.2.3"}).create();

    // This should still have a 0 exit code, since installation succeeded even
    // if precompilation didn't.
    pubGet(error: allOf([
      contains("Failed to precompile foo:hello"),
      contains("Failed to precompile foo:goodbye"),
      contains("Failed to precompile bar:hello"),
      contains("Failed to precompile bar:goodbye")
    ]), exitCode: 0);

    d.dir(p.join(appPath, '.pub', 'bin'), [
      d.file('sdk-version', '0.1.2+3\n'),
      d.dir('foo', [
        d.nothing('hello.dart.snapshot'),
        d.nothing('goodbye.dart.snapshot')
      ]),
      d.dir('bar', [
        d.nothing('hello.dart.snapshot'),
        d.nothing('goodbye.dart.snapshot')
      ])
    ]).validate();
  });
}
