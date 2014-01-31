// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../descriptor.dart' as d;
import '../test_pub.dart';
import '../../lib/src/exit_codes.dart' as exit_codes;

main() {
  initConfig();

  integration("does not allow directory names with --all", () {
    d.dir(appPath, [
      d.appPubspec()
    ]).create();

    schedulePub(args: ["build", "example", "--all"],
        error: 'Build directory names are not allowed if "--all" is passed.',
        exitCode: exit_codes.USAGE);
  });
}
