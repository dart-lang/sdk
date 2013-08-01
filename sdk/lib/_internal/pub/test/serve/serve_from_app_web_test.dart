// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("finds files in the app's web directory", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("web", [
        d.file("index.html", "<body>"),
        d.file("file.dart", "void main() => print('hello');"),
        d.dir("sub", [
          d.file("file.html", "<body>in subdir</body>"),
          d.file("lib.dart", "void foo() => 'foo';"),
        ])
      ])
    ]).create();

    startPubServe();
    requestShouldSucceed("index.html", "<body>");
    requestShouldSucceed("file.dart", "void main() => print('hello');");
    requestShouldSucceed("sub/file.html", "<body>in subdir</body>");
    requestShouldSucceed("sub/lib.dart", "void foo() => 'foo';");
    endPubServe();
  });
}
