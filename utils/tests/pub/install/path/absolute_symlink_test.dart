// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../../../../../pkg/path/lib/path.dart' as path;

import '../../../../pub/exit_codes.dart' as exit_codes;
import '../../test_pub.dart';

main() {
  initConfig();
  integration("generates a symlink with an absolute path if the dependency "
              "path was absolute", () {
    dir("foo", [
      libDir("foo"),
      libPubspec("foo", "0.0.1")
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

    dir("moved").scheduleCreate();

    // Move the app but not the package. Since the symlink is absolute, it
    // should still be able to find it.
    scheduleRename(appPath, path.join("moved", appPath));

    dir("moved", [
      dir(packagesPath, [
        dir("foo", [
          file("foo.dart", 'main() => "foo";')
        ])
      ])
    ]).scheduleValidate();
  });
}