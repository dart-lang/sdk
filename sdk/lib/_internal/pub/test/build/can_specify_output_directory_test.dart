// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as path;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("can specify the output directory to build into", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir('web', [
        d.file('file.txt', 'web')
      ])
    ]).create();

    var outDir = path.join("out", "dir");
    schedulePub(args: ["build", "-o", outDir],
        output: new RegExp('Built 1 file to "$outDir".'));

    d.dir(appPath, [
      d.dir("out", [
        d.dir("dir", [
          d.dir("web", [
            d.file("file.txt", "web")
          ]),
        ])
      ])
    ]).validate();
  });
}
