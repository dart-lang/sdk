// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  // This is a regression test for https://dartbug.com/15183. The code that
  // stripped .dart files from release builds was in the forwarding transformer,
  // and that transformer was applied to all loaded packages. That meant that
  // if the root package imported a .dart file from another package, the
  // forwarding transformer in that package would remove the file before
  // dart2js could find it when compiling the entrypoint in the root package.

  integration("dart2js can find imports across packages", () {
    // Dart2js can take a long time to compile dart code, so we increase the
    // timeout to cope with that.
    currentSchedule.timeout *= 3;

    d.dir("foo", [
      d.libPubspec("foo", "0.0.1"),
      d.dir("lib", [
        d.file("foo.dart",
            """
            library foo;
            foo() => 'foo';
            """)
      ])
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": "../foo"}
      }),
      d.dir("web", [
        d.file("main.dart",
            """
            import 'package:foo/foo.dart';
            main() => print(foo());
            """)
      ])
    ]).create();

    schedulePub(args: ["build"],
        output: new RegExp(r"Built 3 files!"));

    d.dir(appPath, [
      d.dir('build', [
        d.dir('web', [
          d.matcherFile('main.dart.js', isNot(isEmpty)),
          d.matcherFile('main.dart.precompiled.js', isNot(isEmpty)),
          d.matcherFile('main.dart.js.map', isNot(isEmpty))
        ])
      ])
    ]).validate();
  });
}
