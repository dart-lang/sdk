// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("doesn't serve .gitignored assets in a path dependency", () {
    ensureGit();

    d.dir(appPath, [
      d.appPubspec({"foo": {"path": "../foo"}}),
    ]).create();

    d.git("foo", [
      d.libPubspec("foo", "1.0.0"),
      d.dir("lib", [
        d.file("outer.txt", "outer contents"),
        d.file("visible.txt", "visible"),
        d.dir("dir", [
          d.file("inner.txt", "inner contents"),
        ])
      ]),
      d.file(".gitignore", "/lib/outer.txt\n/lib/dir")
    ]).create();

    pubServe(shouldGetFirst: true);
    requestShould404("packages/foo/outer.txt");
    requestShould404("packages/foo/dir/inner.txt");
    requestShouldSucceed("packages/foo/visible.txt", "visible");
    endPubServe();
  });
}
