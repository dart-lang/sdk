// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'package:path/path.dart' as path;

import '../../lib/src/exit_codes.dart' as exit_codes;

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  initConfig();
  integration("uses what's in the lockfile regardless of the pubspec", () {
    d.dir("foo", [
      d.libDir("foo"),
      d.libPubspec("foo", "1.0.0")
    ]).create();

    d.dir(appPath, [
      d.appPubspec({
        "foo": {"path": path.join(sandboxDir, "foo")}
      })
    ]).create();

    pubInstall();

    // Add a dependency on "bar" and remove "foo", but don't run "pub install".
    d.dir(appPath, [
      d.appPubspec({
        "bar": "any"
      })
    ]).create();

    schedulePub(args: ["list-package-dirs", "--format=json"],
        outputJson: {
          "foo": path.join(sandboxDir, "foo")
        });
  });
}