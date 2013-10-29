// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("generates minified JavaScript", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('main.dart', 'void main() => print("hello");')
      ])
    ]).create();

    schedulePub(args: ["build"],
        output: new RegExp(r"Built 1 file!"),
        exitCode: 0);

    d.dir(appPath, [
      d.dir('build', [
        d.matcherFile('main.dart.js', isMinifiedDart2JSOutput)
      ])
    ]).validate();
  });
}
