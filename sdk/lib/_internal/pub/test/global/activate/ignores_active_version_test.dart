// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../test_pub.dart';

main() {
  initConfig();
  integration('ignores previously activated version',
        () {
    servePackages([
      packageMap("foo", "1.2.3"),
      packageMap("foo", "1.3.0")
    ]);

    // Activate 1.2.3.
    schedulePub(args: ["global", "activate", "foo", "1.2.3"]);

    // Activating it again resolves to the new best version.
    schedulePub(args: ["global", "activate", "foo", ">1.0.0"], output: """
        Package foo is currently active at version 1.2.3.
        Resolving dependencies...
        + foo 1.3.0
        Downloading foo 1.3.0...
        Activated foo 1.3.0.""");
  });
}
