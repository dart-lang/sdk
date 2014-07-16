// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'package:path/path.dart' as path;

import '../../lib/src/exit_codes.dart' as exit_codes;
import '../../lib/src/io.dart';
import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  // This is a regression test for #20065.
  integration("reports a missing pubspec error using JSON", () {
    d.dir(appPath).create();

    schedulePub(args: ["list-package-dirs", "--format=json"],
        outputJson: {
          "error":
            'Could not find a file named "pubspec.yaml" in "'
                '${canonicalize(path.join(sandboxDir, appPath))}".'
        },
        exitCode: 1);
  });
}