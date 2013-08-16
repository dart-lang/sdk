// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'package:path/path.dart' as path;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('includes dev dependencies in the results', () {
    d.dir("foo", [
      d.libDir("foo"),
      d.libPubspec("foo", "1.0.0")
    ]).create();

    d.dir(appPath, [
      d.pubspec({
        "name": "myapp",
        "dev_dependencies": {
          "foo": {"path": path.join(sandboxDir, "foo")}
        }
      })
    ]).create();

    pubInstall();

    schedulePub(args: ["list-package-dirs", "--format=json"],
        outputJson: {
          "foo": path.join(sandboxDir, "foo")
        });
  });
}