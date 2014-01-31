// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("build --all finds assets in all buildable directories", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('benchmark', [
        d.file('file.txt', 'benchmark')
      ]),
      d.dir('bin', [
        d.file('file.txt', 'bin')
      ]),
      d.dir('example', [
        d.file('file.txt', 'example')
      ]),
      d.dir('test', [
        d.file('file.txt', 'test')
      ]),
      d.dir('web', [
        d.file('file.txt', 'web')
      ]),
      d.dir('unknown', [
        d.file('file.txt', 'unknown')
      ])
    ]).create();

    schedulePub(args: ["build", "--all"],
        output: new RegExp(r"Built 5 files!"));

    d.dir(appPath, [
      d.dir('build', [
        d.dir('benchmark', [
          d.file('file.txt', 'benchmark')
        ]),
        d.dir('bin', [
          d.file('file.txt', 'bin')
        ]),
        d.dir('example', [
          d.file('file.txt', 'example')
        ]),
        d.dir('test', [
          d.file('file.txt', 'test')
        ]),
        d.dir('web', [
          d.file('file.txt', 'web')
        ]),
        // Only includes known buildable directories.
        d.nothing('unknown')
      ])
    ]).validate();
  });
}
