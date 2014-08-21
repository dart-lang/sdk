// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('installs and activates the best version of a package', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "1.2.3");
      builder.serve("foo", "2.0.0-wildly.unstable");
    });

    schedulePub(args: ["global", "activate", "foo"], output: """
        Resolving dependencies...
        + foo 1.2.3 (2.0.0-wildly.unstable available)
        Downloading foo 1.2.3...
        Activated foo 1.2.3.""");

    // Should be in global package cache.
    d.dir(cachePath, [
      d.dir('global_packages', [
        d.matcherFile('foo.lock', contains('1.2.3'))
      ])
    ]).validate();
  });
}
