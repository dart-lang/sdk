// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../../../pkg/path/lib/path.dart' as path;

import '../../../../pub/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('path dependency when path is a file', () {
    dir('foo', [
      libDir('foo'),
      libPubspec('foo', '0.0.1')
    ]).scheduleCreate();

    file('dummy.txt', '').scheduleCreate();
    var dummyPath = path.join(sandboxDir, 'dummy.txt');

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": dummyPath}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        error: new RegExp("Path dependency for package 'foo' must refer to a "
                          "directory, not a file. Was '$dummyPath'."),
        exitCode: exit_codes.DATA);
  });
}