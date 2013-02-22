// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../../../pkg/pathos/lib/path.dart' as path;

import '../../test_pub.dart';

main() {
  initConfig();
  integration('path dependency with absolute path', () {
    dir('foo', [
      libDir('foo'),
      libPubspec('foo', '0.0.1')
    ]).scheduleCreate();

    dir(appPath, [
      pubspec({
        "name": "myapp",
        "dependencies": {
          "foo": {"path": path.join(sandboxDir, "foo")}
        }
      })
    ]).scheduleCreate();

    schedulePub(args: ["install"],
        output: new RegExp(r"Dependencies installed!$"));

    dir(packagesPath, [
      dir("foo", [
        file("foo.dart", 'main() => "foo";')
      ])
    ]).scheduleValidate();

    // Move the packages directory and ensure the symlink still works. That
    // will validate that we actually created an absolute symlink.
    dir("moved").scheduleCreate();
    scheduleRename(packagesPath, "moved/packages");

    dir("moved/packages", [
      dir("foo", [
        file("foo.dart", 'main() => "foo";')
      ])
    ]).scheduleValidate();
  });
}