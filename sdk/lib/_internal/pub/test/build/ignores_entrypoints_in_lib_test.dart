// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("ignores entrypoint Dart files in lib/", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('lib', [
        d.file('file.dart', 'void main() => print("hello");'),
      ]),
      d.dir('web', [
        d.file('index.html', 'html'),
      ])
    ]).create();

    schedulePub(args: ["build", "--all"],
        output: new RegExp(r"Built 1 file!"));

    d.dir(appPath, [
      d.dir('build', [
        d.nothing('lib'),
        d.dir('web', [
          d.file('index.html', 'html')
        ])
      ])
    ]).validate();
  });
}
