// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../test_pub.dart';

main() {
  initConfig();
  integration('activating a package installs its dependencies too', () {
    servePackages([
      packageMap("foo", "1.0.0", {"bar": "any"}),
      packageMap("bar", "1.0.0", {"baz": "any"}),
      packageMap("baz", "1.0.0")
    ]);

    schedulePub(args: ["global", "activate", "foo"], output: allOf([
      contains("Downloading bar 1.0.0..."),
      contains("Downloading baz 1.0.0...")
    ]));
  });
}
