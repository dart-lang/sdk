// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../../pub/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('path dependencies cannot use relative paths', () {
    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": "../foo"}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        error: new RegExp("Path dependency for package 'foo' must be an "
                          "absolute path. Was '../foo'."),
        exitCode: exit_codes.DATA);
  });
}