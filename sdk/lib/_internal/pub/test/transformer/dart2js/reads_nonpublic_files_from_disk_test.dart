// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';

main() {
  initConfig();
  integration("reads imported files from non-public directories straight from"
      "the file system", () {
    // Since the "private" directory isn't served by the barback server, the
    // relative import for it will fail if the dart2js transformer tries to
    // get it from barback. This is a regression test for dartbug.com/15688.
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("private", [
        d.file("lib.dart", """
library lib;
lib() => 'libtext';
""")
      ]),
      d.dir("web", [
        d.file("main.dart", """
import '../private/lib.dart';
void main() {
  print(lib());
}
""")
      ])
    ]).create();

    pubServe();
    requestShouldSucceed("main.dart.js", contains("libtext"));
    endPubServe();
  });
}
