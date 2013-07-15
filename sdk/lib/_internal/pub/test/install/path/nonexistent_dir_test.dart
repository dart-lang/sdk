// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';

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

    pubInstall(error: "Could not find package 'foo' at '$badPath'.");
  });
}