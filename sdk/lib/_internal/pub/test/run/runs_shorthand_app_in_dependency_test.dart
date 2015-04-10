// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('runs a shorthand Dart application in a dependency', () {
    d.dir("foo", [
      d.libPubspec("foo", "1.0.0"),
      d.dir("bin", [
        d.file("foo.dart", "main() => print('foo');")
      ])
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"}
        }
      })
    ]).create();

    pubGet();

    var pub = pubRun(args: ["foo"]);
    pub.stdout.expect("foo");
    pub.shouldExit();
  });
}
