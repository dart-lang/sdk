// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("fails if given directories are not buildable", () {
    d.appDir().create();

    schedulePub(args: ["build", "foo", "bar"],
        error: 'Unsupported build directories "bar" and "foo".\n'
               'The allowed directories are "benchmark", "bin", "example", '
                   '"test" and "web".',
        exitCode: exit_codes.USAGE);
  });
}
