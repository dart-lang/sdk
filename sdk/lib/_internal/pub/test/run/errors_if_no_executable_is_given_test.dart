// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('Errors if the executable does not exist.', () {
    d.dir(appPath, [
      d.appPubspec()
    ]).create();

    schedulePub(args: ["run"],
        error: """
Must specify an executable to run.

Usage: pub run <executable> [args...]
-h, --help    Print usage information for this command.
""",
        exitCode: exit_codes.USAGE);
  });
}
