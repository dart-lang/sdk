// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('activates a different version after deactivating', () {
    servePackages([
      packageMap("foo", "1.0.0"),
      packageMap("foo", "2.0.0")
    ]);

    // Activate an old version.
    schedulePub(args: ["global", "activate", "foo", "1.0.0"]);

    schedulePub(args: ["global", "deactivate", "foo"],
        output: "Deactivated package foo 1.0.0.");

    // Activating again should forget the old version.
    schedulePub(args: ["global", "activate", "foo"], output: """
Downloading foo 2.0.0...
Resolving dependencies...
Activated foo 2.0.0.
    """);
  });
}
