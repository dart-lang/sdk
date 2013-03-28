// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../../../pub/exit_codes.dart' as exit_codes;
import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('path dependency when path is a d.file', () {
    d.dir('foo', [
      d.libDir('foo'),
      d.libPubspec('foo', '0.0.1')
    ]).create();

    d.file('dummy.txt', '').create();
    var dummyPath = path.join(sandboxDir, 'dummy.txt');

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": dummyPath}
        }
      })
    ]).create();

    // TODO(rnystrom): The "\" in a Windows path gets treated like a regex
    // character, so hack escape. A better fix is to use a literal string
    // instead of a RegExp to validate, but that requires us to move the
    // stack traces out of the stderr when we invoke pub. See also: #4706.
    var escapePath = dummyPath.replaceAll(r"\", r"\\");

    schedulePub(args: ['install'],
        error: new RegExp("Path dependency for package 'foo' must refer to a "
                          "directory, not a file. Was '$escapePath'."),
        exitCode: exit_codes.DATA);
  });
}