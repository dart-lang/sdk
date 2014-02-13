// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("'assets' URLs look in the dependency's asset directory", () {
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
      })
    ]).create();

    pubServe(shouldGetFirst: true);
    requestShouldSucceed("assets/foo/foo.txt", "foo");
    requestShouldSucceed("assets/foo/sub/bar.txt", "bar");

    // "assets" cannot be in a subpath of the URL:
    requestShould404("foo/assets/foo/foo.txt");
    requestShould404("a/b/assets/foo/sub/bar.txt");
    endPubServe();
  });
}
