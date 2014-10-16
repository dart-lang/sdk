// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../descriptor.dart' as d;
import '../test_pub.dart';

main() {
  // Pub uses NTFS junction points to create links in the packages directory.
  // These (unlike the symlinks that are supported in Vista and later) do not
  // support relative paths. So this test, by design, will not pass on Windows.
  // So just skip it.
  if (Platform.operatingSystem == "windows") return;

  initConfig();
  integration('uses a relative symlink for the self link', () {
    d.dir(appPath, [d.appPubspec(), d.libDir('foo')]).create();

    pubGet();

    scheduleRename(appPath, "moved");

    d.dir(
        "moved",
        [
            d.dir(
                "packages",
                [d.dir("myapp", [d.file('foo.dart', 'main() => "foo";')])])]).validate();
  });

  integration('uses a relative symlink for secondary packages directory', () {
    d.dir(appPath, [d.appPubspec(), d.libDir('foo'), d.dir("bin")]).create();

    pubGet();

    scheduleRename(appPath, "moved");

    d.dir(
        "moved",
        [
            d.dir(
                "bin",
                [
                    d.dir(
                        "packages",
                        [d.dir("myapp", [d.file('foo.dart', 'main() => "foo";')])])])]).validate();
  });
}
