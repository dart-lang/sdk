// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();

  integration("fails if 'web' doesn't exist and no directory is specified", () {
    d.appDir().create();

    schedulePub(args: ["build"],
        error: 'Directory "web" does not exist.',
        exitCode: exit_codes.DATA);
  });
}
