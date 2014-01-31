// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("fails if any specified build directories don't exist", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('example', [
        d.file('file.txt', 'example')
      ]),
      d.dir('web', [
        d.file('file.txt', 'test')
      ])
    ]).create();

    schedulePub(args: ["build", "benchmark", "example", "test", "web"],
        error: 'Directories "benchmark" and "test" do not exist.',
        exitCode: exit_codes.DATA);
  });
}
