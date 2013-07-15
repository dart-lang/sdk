// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("reports Dart parse errors", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir(appPath, [
      d.appPubspec([]),
      d.dir('web', [
        d.file('file.txt', 'contents'),
        d.file('file.dart', 'void void;'),
        d.dir('subdir', [
          d.file('subfile.dart', 'void void;')
        ])
      ])
    ]).create();

    schedulePub(args: ["deploy"],
        error: new RegExp(
            r"^Error on line 1 of .*[/\\]file\.dart:(.|\n)*"
            r"^Error on line 1 of .*[/\\]subfile\.dart:",
            multiLine: true),
        output: '''
Finding entrypoints...
Copying   web| => deploy|
'''.replaceAll('|', path.separator),
        exitCode: 0);

    d.dir(appPath, [
      d.dir('deploy', [
        d.matcherFile('file.txt', 'contents'),
        d.nothing('file.dart.js'),
        d.nothing('file.dart'),
        d.nothing('subdir')
      ])
    ]).validate();
  });
}
