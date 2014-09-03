// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../test_pub.dart';

main() {
  initConfig();
  integration('activates a different version after deactivating', () {
    servePackages((builder) {
      builder.serve("foo", "1.0.0");
      builder.serve("foo", "2.0.0");
    });

    // Activate an old version.
    schedulePub(args: ["global", "activate", "foo", "1.0.0"]);

    schedulePub(args: ["global", "deactivate", "foo"],
        output: "Deactivated package foo 1.0.0.");

    // Activating again should forget the old version.
    schedulePub(args: ["global", "activate", "foo"], output: """
        Resolving dependencies...
        + foo 2.0.0
        Downloading foo 2.0.0...
        Precompiling executables...
        Loading source assets...
        Activated foo 2.0.0.""");
  });
}
