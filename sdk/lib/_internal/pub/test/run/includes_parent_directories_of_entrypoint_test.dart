// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as path;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

const SCRIPT = r"""
import '../../a.dart';
import '../b.dart';
main() {
  print("$a $b");
}
""";

main() {
  initConfig();
  integration('allows assets in parent directories of the entrypoint to be'
      'accessed', () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("tool", [
        d.file("a.dart", "var a = 'a';"),
        d.dir("a", [
          d.file("b.dart", "var b = 'b';"),
          d.dir("b", [
            d.file("app.dart", SCRIPT)
          ])
        ])
      ])
    ]).create();

    var pub = pubRun(args: [path.join("tool", "a", "b", "app")]);
    pub.stdout.expect("a b");
    pub.shouldExit();
  });
}
