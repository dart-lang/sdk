// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../serve/utils.dart';

main() {
  initConfig();
  // Regression test for issue 23113
  integration('runs a named Dart application in a dependency', () {
    servePackages((builder) {
      builder.serve('foo', '1.0.0', pubspec: {
        'name': 'foo',
        'version': '1.0.0'
      }, contents: [
        d.dir("bin", [
          d.file("bar.dart", "main() => print('foobar');")
        ])
      ]);
    });

    d.dir(appPath, [
      d.appPubspec({"foo": null})
    ]).create();

    pubGet();

    var pub = pubRun(args: ["foo:bar"]);
    pub.stdout.expect("foobar");
    pub.shouldExit();

    d.dir("foo", [
      d.libPubspec("foo", "2.0.0"),
      d.dir("bin", [
        d.file("bar.dart", "main() => print('different');")
      ])
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {"foo": {"path": "../foo"}}
      })
    ]).create();

    pubGet();

    pub = pubRun(args: ["foo:bar"]);
    pub.stdout.expect("different");
    pub.shouldExit();
  });
}
