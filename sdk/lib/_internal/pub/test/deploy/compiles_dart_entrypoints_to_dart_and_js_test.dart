// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("compiles Dart entrypoints to Dart and JS", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir(appPath, [
      d.appPubspec([]),
      d.dir('web', [
        d.file('file.dart', 'void main() => print("hello");'),
        d.dir('subdir', [
          d.file('subfile.dart', 'void main() => print("ping");')
        ])
      ])
    ]).create();

    schedulePub(args: ["deploy"],
        output: '''
Finding entrypoints...
Copying   web|                    => deploy|
Compiling web|file.dart           => deploy|file.dart.js
Compiling web|file.dart           => deploy|file.dart
Compiling web|subdir|subfile.dart => deploy|subdir|subfile.dart.js
Compiling web|subdir|subfile.dart => deploy|subdir|subfile.dart
'''.replaceAll('|', path.separator),
        exitCode: 0);

    d.dir(appPath, [
      d.dir('deploy', [
        d.matcherFile('file.dart.js', isNot(isEmpty)),
        d.matcherFile('file.dart', isNot(isEmpty)),
        d.dir('subdir', [
          d.matcherFile('subfile.dart.js', isNot(isEmpty)),
          d.matcherFile('subfile.dart', isNot(isEmpty))
        ])
      ])
    ]).validate();
  });
}
