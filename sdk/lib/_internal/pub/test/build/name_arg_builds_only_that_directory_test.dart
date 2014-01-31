// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("if a dir name is given, only includes that dir", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('asset', [
        d.file('file.txt', 'asset')
      ]),
      d.dir('example', [
        d.file('file.txt', 'example')
      ]),
      d.dir('web', [
        d.file('file.txt', 'test')
      ])
    ]).create();

    schedulePub(args: ["build", "example"],
        output: new RegExp(r"Built 2 files!"));

    d.dir(appPath, [
      d.dir('build', [
        d.dir('example', [
          d.file('file.txt', 'example'),
          d.dir('assets', [
            d.dir('myapp', [
              d.file('file.txt', 'asset')
            ])
          ])
        ]),
        // Only example should be built.
        d.nothing('web')
      ])
    ]).validate();
  });
}
