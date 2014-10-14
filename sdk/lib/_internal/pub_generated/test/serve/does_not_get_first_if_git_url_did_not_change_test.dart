// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../descriptor.dart' as d;
import '../test_pub.dart';
import 'utils.dart';

main() {
  initConfig();
  integration("does not get first if a git dependency's url is unchanged", () {
    d.git('foo.git', [d.libPubspec('foo', '1.0.0'), d.libDir("foo")]).create();

    d.appDir({
      "foo": {
        "git": "../foo.git"
      }
    }).create();

    pubGet();
    pubServe(shouldGetFirst: false);
    requestShouldSucceed("packages/foo/foo.dart", 'main() => "foo";');
    endPubServe();
  });
}
