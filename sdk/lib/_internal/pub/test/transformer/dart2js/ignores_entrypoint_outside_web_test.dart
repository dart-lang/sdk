// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../../serve/utils.dart';

main() {
  initConfig();
  integration("ignores a Dart entrypoint outside web", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("lib", [
        d.file("main.dart", "void main() => print('hello');")
      ])
    ]).create();

    startPubServe();
    requestShould404("packages/myapp/main.dart.js");
    endPubServe();
  });
}
