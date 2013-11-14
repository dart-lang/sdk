// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("does not serve .dart files in release mode", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("lib", [
        d.file("lib.dart", "lib() => print('hello');"),
      ]),
      d.dir("web", [
        d.file("file.dart", "main() => print('hello');"),
        d.dir("sub", [
          d.file("sub.dart", "main() => 'foo';"),
        ])
      ])
    ]).create();

    pubServe(args: ["--mode", "release"]);
    requestShould404("file.dart");
    requestShould404("packages/myapp/lib.dart");
    requestShould404("sub/sub.dart");
    endPubServe();
  });
}
