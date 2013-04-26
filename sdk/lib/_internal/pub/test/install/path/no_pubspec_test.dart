// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'dart:io';

import 'package:pathos/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  initConfig();
  integration('path dependency to non-package directory', () {
    // Make an empty directory.
    d.dir('foo').create();
    var fooPath = path.join(sandboxDir, "foo");

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": fooPath}
        }
      })
    ]).create();

    schedulePub(args: ['install'],
        error: new RegExp('Package "foo" doesn\'t have a pubspec.yaml file.'),
        exitCode: 1);
  });
}