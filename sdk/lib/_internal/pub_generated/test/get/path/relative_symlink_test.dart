// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS d.file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE d.file.

import 'dart:io';

import 'package:path/path.dart' as path;

import '../../descriptor.dart' as d;
import '../../test_pub.dart';

main() {
  // Pub uses NTFS junction points to create links in the packages directory.
  // These (unlike the symlinks that are supported in Vista and later) do not
  // support relative paths. So this test, by design, will not pass on Windows.
  // So just skip it.
  if (Platform.operatingSystem == "windows") return;

  initConfig();
  integration(
      "generates a symlink with a relative path if the dependency "
          "path was relative",
      () {
    d.dir("foo", [d.libDir("foo"), d.libPubspec("foo", "0.0.1")]).create();

    d.dir(appPath, [d.appPubspec({
        "foo": {
          "path": "../foo"
        }
      })]).create();

    pubGet();

    d.dir("moved").create();

    // Move the app and package. Since they are still next to each other, it
    // should still be found.
    scheduleRename("foo", path.join("moved", "foo"));
    scheduleRename(appPath, path.join("moved", appPath));

    d.dir(
        "moved",
        [
            d.dir(
                packagesPath,
                [d.dir("foo", [d.file("foo.dart", 'main() => "foo";')])])]).validate();
  });
}
