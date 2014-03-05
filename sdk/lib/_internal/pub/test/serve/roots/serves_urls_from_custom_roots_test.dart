// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'package:path/path.dart' as p;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';
import '../utils.dart';

main() {
  initConfig();
  integration("serves URLs from custom roots", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("example", [
        d.dir("foo", [d.file("bar", "contents")])
      ]),
      d.dir("dir", [d.file("baz", "contents")]),
      d.dir("web", [d.file("bang", "contents")])
    ]).create();

    pubServe(args: [p.join("example", "foo"), "dir"]);
    requestShouldSucceed("bar", "contents", root: p.join("example", "foo"));
    requestShouldSucceed("baz", "contents", root: "dir");
    requestShould404("bang", root: "dir");
    endPubServe();
  });
}
