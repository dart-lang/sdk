// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('performs verison solver backtracking if necessary', () {
    servePackages([
      packageMap("foo", "1.1.0")..addAll({
        "environment": {"sdk": ">=0.1.2 <0.2.0"}
      }),
      packageMap("foo", "1.2.0")..addAll({
        "environment": {"sdk": ">=0.1.3 <0.2.0"}
      }),
    ]);

    schedulePub(args: ["global", "activate", "foo"]);

    // foo 1.2.0 won't be picked because its SDK constraint conflicts with the
    // dummy SDK version 0.1.2+3.
    d.dir(cachePath, [
      d.dir('global_packages', [
        d.matcherFile('foo.lock', contains('1.1.0'))
      ])
    ]).validate();
  });
}
