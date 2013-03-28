// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'dart:io';

import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../../pub/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('path dependency to non-existent directory', () {
    var badPath = path.join(sandboxDir, "bad_path");

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": badPath}
        }
      })
    ]).create();

    // TODO(rnystrom): The "\" in a Windows path gets treated like a regex
    // character, so hack escape. A better fix is to use a literal string
    // instead of a RegExp to validate, but that requires us to move the
    // stack traces out of the stderr when we invoke pub. See also: #4706.
    var escapePath = badPath.replaceAll(r"\", r"\\");

    schedulePub(args: ['install'],
        error:
            new RegExp("Could not find package 'foo' at '$escapePath'."),
        exitCode: exit_codes.DATA);
  });
}