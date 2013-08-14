// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("'assets' URLs look in the app's 'asset' directory", () {
    d.dir(appPath, [
      d.appPubspec(),
      d.dir("asset", [
        d.file("foo.txt", "foo"),
        d.dir("sub", [
          d.file("bar.txt", "bar"),
        ])
      ])
    ]).create();

    startPubServe();
    requestShouldSucceed("assets/myapp/foo.txt", "foo");
    requestShouldSucceed("assets/myapp/sub/bar.txt", "bar");

    // "assets" can be in a subpath of the URL:
    requestShouldSucceed("foo/assets/myapp/foo.txt", "foo");
    requestShouldSucceed("a/b/assets/myapp/sub/bar.txt", "bar");
    endPubServe();
  });
}
