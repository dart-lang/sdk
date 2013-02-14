// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import '../../../../../pkg/path/lib/path.dart' as path;

import '../../test_pub.dart';

main() {
  initConfig();
  integration('path dependency to non-package directory', () {
    // Make an empty directory.
    dir('foo').scheduleCreate();
    var fooPath = path.join(sandboxDir, "foo");

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": fooPath}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ['install'],
        error: new RegExp('Package "foo" doesn\'t have a pubspec.yaml file.'),
        exitCode: 1);
  });
}