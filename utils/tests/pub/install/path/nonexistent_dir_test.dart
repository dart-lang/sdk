// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../../../../../pkg/path/lib/path.dart' as path;

import '../../../../pub/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('path dependency to non-existent directory', () {
    var badPath = path.join(sandboxDir, "bad_path");

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": badPath}
        }
      })
    ]).scheduleCreate();

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