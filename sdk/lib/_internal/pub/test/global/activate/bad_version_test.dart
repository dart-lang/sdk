// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('fails if the version constraint cannot be parsed', () {
    schedulePub(args: ["global", "activate", "foo", "1.0"],
        error: """
            Could not parse version "1.0". Unknown text at "1.0".

            Usage: pub global activate <package> [version]
            -h, --help    Print usage information for this command.

            Run "pub help" to see global options.
            """,
        exitCode: exit_codes.USAGE);
  });
}
