// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:path/path.dart' as p;

import '../../../lib/src/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('errors if the script does not exist.', () {
    servePackages((builder) => builder.serve("foo", "1.0.0"));

    schedulePub(args: ["global", "activate", "foo"]);

    var pub = pubRun(global: true, args: ["foo:script"]);
    pub.stderr.expect("Could not find ${p.join("bin", "script.dart")}.");
    pub.shouldExit(exit_codes.NO_INPUT);
  });
}
