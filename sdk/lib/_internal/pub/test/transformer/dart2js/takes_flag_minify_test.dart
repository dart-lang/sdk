// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';

main() {
  initConfig();
  integration("generates minified JS if the flag is set", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("web", [
        d.file("main.dart", "void main() => print('hello');")
      ])
    ]).create();

    startPubServe(args: ["--minify"]);
    requestShouldSucceed("main.dart.js", isMinifiedDart2JSOutput);
    endPubServe();
  });
}
