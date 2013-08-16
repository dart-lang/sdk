// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'package:path/path.dart' as path;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration('prints the local paths to all packages in the lockfile', () {
    servePackages([packageMap("bar", "1.0.0")]);

    d.dir("foo", [
      d.libDir("foo"),
      d.libPubspec("foo", "1.0.0")
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": path.join(sandboxDir, "foo")},
        "bar": "any"
      })
    ]).create();

    pubInstall();

    schedulePub(args: ["list-package-dirs", "--format=json"],
        outputJson: {
          "foo": path.join(sandboxDir, "foo"),
          "bar": port.then((p) => path.join(sandboxDir, cachePath, "hosted",
              "localhost%58$p", "bar-1.0.0"))
        });
  });
}