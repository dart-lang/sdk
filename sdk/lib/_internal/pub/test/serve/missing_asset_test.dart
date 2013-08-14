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
  integration("responds with a 404 for missing assets", () {
    d.dir(appPath, [
      d.appPubspec()
    ]).create();

    startPubServe();
    requestShould404("index.html");
    requestShould404("packages/myapp/nope.dart");
    requestShould404("assets/myapp/nope.png");
    requestShould404("dir/packages/myapp/nope.dart");
    requestShould404("dir/assets/myapp/nope.png");
    endPubServe();
  });
}
