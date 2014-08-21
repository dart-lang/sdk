// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('errors if the package is not activated', () {
    serveNoPackages();

    schedulePub(args: ["global", "run", "foo:bar"],
        error: startsWith("No active package foo."),
        exitCode: exit_codes.DATA);
  });
}
