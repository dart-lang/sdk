// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('errors if the constraint matches no versions', () {
    servePackages([
      packageMap("foo", "1.0.0"),
      packageMap("foo", "1.0.1")
    ]);

    schedulePub(args: ["global", "activate", "foo", ">1.1.0"],
        error: "Package foo has no versions that match >1.1.0.",
        exitCode: exit_codes.DATA);
  });
}
