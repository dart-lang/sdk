// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("doesn't choke on an explicit dart2js transformer", () {
    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "transformers": [r"$dart2js"]
      }),
      d.dir("bin", [
        d.file("script.dart", "main() => print('Hello!');")
      ])
    ]).create();

    var pub = pubRun(args: ["script"]);
    pub.stdout.expect("Hello!");
    pub.shouldExit(0);
  });
}
