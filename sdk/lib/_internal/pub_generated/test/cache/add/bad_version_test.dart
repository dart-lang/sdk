// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('fails if the version constraint cannot be parsed', () {
    schedulePub(args: ["cache", "add", "foo", "-v", "1.0"], error: """
            Could not parse version "1.0". Unknown text at "1.0".
            
            Usage: pub cache add <package> [--version <constraint>] [--all]
            -h, --help       Print usage information for this command.
                --all        Install all matching versions.
            -v, --version    Version constraint.

            Run "pub help" to see global options.
            See http://dartlang.org/tools/pub/cmd/pub-cache.html for detailed documentation.
            """, exitCode: exit_codes.USAGE);
  });
}
