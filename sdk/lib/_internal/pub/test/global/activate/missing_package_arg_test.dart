// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('fails if no package was given', () {
    schedulePub(args: ["global", "activate"],
        error: """
            No package to activate given.

            Usage: pub global activate <package> [version]
            -h, --help    Print usage information for this command.
            """,
        exitCode: exit_codes.USAGE);
  });
}
