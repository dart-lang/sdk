// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';

main() {
  initConfig();
  integration("generates unminified JS by default", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("web", [
        d.file("main.dart", "void main() => print('hello');")
      ])
    ]).create();

    startPubServe();
    requestShouldSucceed("main.dart.js", isUnminifiedDart2JSOutput);
    endPubServe();
  });
}
