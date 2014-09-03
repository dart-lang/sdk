// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('uses the 1.6-style lockfile if necessary', () {
    servePackages((builder) {
      builder.serve("bar", "1.0.0");
      builder.serve("foo", "1.0.0", deps: {"bar": "any"}, contents: [
        d.dir("bin", [
          d.file("script.dart", """
              import 'package:bar/bar.dart' as bar;

              main(args) => print(bar.main());""")
        ])
      ]);
    });

    schedulePub(args: ["cache", "add", "foo"]);
    schedulePub(args: ["cache", "add", "bar"]);

    d.dir(cachePath, [
      d.dir('global_packages', [
        d.file('foo.lock', '''
packages:
  foo:
    description: foo
    source: hosted
    version: "1.0.0"
  bar:
    description: bar
    source: hosted
    version: "1.0.0"''')
      ])
    ]).create();

    var pub = pubRun(global: true, args: ["foo:script"]);
    pub.stdout.expect("bar 1.0.0");
    pub.shouldExit();

    d.dir(cachePath, [
      d.dir('global_packages', [
        d.nothing('foo.lock'),
        d.dir('foo', [d.matcherFile('pubspec.lock', contains('1.0.0'))])
      ])
    ]).validate();
  });
}
