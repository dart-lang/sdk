// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('fails if a version is passed with the path source', () {
    schedulePub(args: ["global", "activate", "-spath", "foo", "1.2.3"],
        error: """
            Unexpected argument "1.2.3".

            Usage: pub global activate [--source source] <package> [version]
            -h, --help      Print usage information for this command.
            -s, --source    The source used to find the package.
                            [git, hosted (default), path]

            Run "pub help" to see global options.
            """,
        exitCode: exit_codes.USAGE);
  });
}
