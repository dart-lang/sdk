// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("allows multiple directory name arguments", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('example', [
        d.file('file.txt', 'example')
      ]),
      d.dir('test', [
        d.file('file.txt', 'test')
      ]),
      d.dir('web', [
        d.file('file.txt', 'web')
      ])
    ]).create();

    schedulePub(args: ["build", "example", "test"],
        output: new RegExp(r"Built 2 files!"));

    d.dir(appPath, [
      d.dir('build', [
        d.dir('example', [
          d.file('file.txt', 'example')
        ]),
        d.dir('test', [
          d.file('file.txt', 'test')
        ]),
        d.nothing('web')
      ])
    ]).validate();
  });
}
