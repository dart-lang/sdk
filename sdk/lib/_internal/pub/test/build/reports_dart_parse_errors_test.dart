// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("reports Dart parse errors", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('file.txt', 'contents'),
        d.file('file.dart', 'void void;'),
        d.dir('subdir', [
          d.file('subfile.dart', 'void void;')
        ])
      ])
    ]).create();

    schedulePub(args: ["build"],
        // TODO(rnystrom): Figure out why dart2js errors aren't deterministic.
        // Use a lookahead regexp to do two searches in one regexp.
        // Checked all non-matching cases for bad performance.
        error: new RegExp(
            r"(?=(.|\n)*^Error on line 1 of .*[/\\]file\.dart:)"
            r"(.|\n)*^Error on line 1 of .*[/\\]subfile\.dart:",
            multiLine: true),
        output: new RegExp(r"Building myapp\.\.\.*"),
        exitCode: exit_codes.DATA);

    // Doesn't output anything if an error occurred.
    d.dir(appPath, [
      d.dir('build', [
        d.nothing('web')
      ])
    ]).validate();
  });
}
