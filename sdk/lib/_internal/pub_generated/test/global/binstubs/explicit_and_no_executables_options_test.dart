// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:scheduled_test/scheduled_test.dart';

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("errors if -x and --no-executables are both passed", () {
    d.dir("foo", [d.libPubspec("foo", "1.0.0")]).create();

    schedulePub(
        args: [
            "global",
            "activate",
            "--source",
            "path",
            "../foo",
            "-x",
            "anything",
            "--no-executables"],
        error: contains("Cannot pass both --no-executables and --executable."),
        exitCode: exit_codes.USAGE);
  });
}
