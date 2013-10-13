// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("includes assets from dependencies", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir("foo", [
      d.libPubspec("foo", "0.0.1"),
      d.dir("asset", [
        d.file("foo.txt", "foo"),
        d.dir("sub", [
          d.file("bar.txt", "bar"),
        ])
      ])
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": "../foo"}
      }),
      d.dir("web", [
        d.file("index.html", "html"),
      ])
    ]).create();

    schedulePub(args: ["build"],
        output: new RegExp(r"Built 3 files!"),
        exitCode: 0);

    d.dir(appPath, [
      d.dir('build', [
        d.file("index.html", "html"),
        d.dir('assets', [
          d.dir('foo', [
            d.file('foo.txt', 'foo'),
            d.dir('sub', [
              d.file('bar.txt', 'bar'),
            ]),
          ])
        ])
      ])
    ]).validate();
  });
}
