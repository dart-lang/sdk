// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('keeps previously activated version if it meets the constraint',
        () {
    servePackages([
      packageMap("foo", "1.2.3"),
      packageMap("foo", "1.3.0")
    ]);

    // Activate 1.2.3.
    schedulePub(args: ["global", "activate", "foo", "1.2.3"]);

    // Activating it again re-resolves but maintains the version.
    schedulePub(args: ["global", "activate", "foo", ">1.0.0"], output: """
Package foo is already active at version 1.2.3.
Resolving dependencies...
Activated foo 1.2.3.""");
  });
}
