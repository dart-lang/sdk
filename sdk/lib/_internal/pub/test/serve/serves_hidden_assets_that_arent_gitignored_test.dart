// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("serves hidden assets that aren't .gitignored", () {
    ensureGit();

    d.git(appPath, [
      d.appPubspec(),
      d.dir("web", [
        d.file(".outer.txt", "outer contents"),
        d.dir(".dir", [
          d.file("inner.txt", "inner contents"),
        ])
      ])
    ]).create();

    pubServe();
    requestShouldSucceed(".outer.txt", "outer contents");
    requestShouldSucceed(".dir/inner.txt", "inner contents");
    endPubServe();
  });
}
