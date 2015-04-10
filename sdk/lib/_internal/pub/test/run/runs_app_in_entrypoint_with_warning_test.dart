// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

import '../descriptor.dart' as d;
import '../test_pub.dart';

const SCRIPT = """
import 'dart:io';

main() {
  stdout.writeln("stdout output");
  stderr.writeln("stderr output");
  exitCode = 123;
}
""";

main() {
  initConfig();
  integration('runs a Dart application in the entrypoint package', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("bin", [
        d.file("script.dart", SCRIPT)
      ])
    ]).create();

    var pub = pubRun(args: ["script"]);
    pub.stdout.expect("stdout output");
    pub.stderr.expect(
        'In future releases, "pub run script" will mean the same thing as "pub '
            'run script:script".');
    pub.stderr.expect(
        'Run "pub run ${p.join('bin', 'script')}" explicitly to run the local '
            'executable.');
    pub.stderr.expect("stderr output");
    pub.shouldExit(123);
  });
}
