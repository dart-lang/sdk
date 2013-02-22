// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import '../../../../../pkg/pathos/lib/path.dart' as path;

import '../../../../pub/io.dart';
import '../../test_pub.dart';

main() {
  initConfig();
  integration('re-installs a package if it has an empty "lib" directory', () {

    servePackages([package("foo", "1.2.3")]);

    // Set up a cache with a broken foo package.
    dir(cachePath, [
      dir('hosted', [
        async(port.then((p) => dir('localhost%58$p', [
          dir("foo-1.2.3", [
            libPubspec("foo", "1.2.3"),
            // Note: empty "lib" directory.
            dir("lib", [])
          ])
        ])))
      ])
    ]).scheduleCreate();

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp("Dependencies installed!\$"));

    cacheDir({"foo": "1.2.3"}).scheduleValidate();
    packagesDir({"foo": "1.2.3"}).scheduleValidate();
  });

  integration('re-installs a package if it has no pubspec', () {

    servePackages([package("foo", "1.2.3")]);

    // Set up a cache with a broken foo package.
    dir(cachePath, [
      dir('hosted', [
        async(port.then((p) => dir('localhost%58$p', [
          dir("foo-1.2.3", [
            libDir("foo")
            // Note: no pubspec.
          ])
        ])))
      ])
    ]).scheduleCreate();

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp("Dependencies installed!\$"));

    cacheDir({"foo": "1.2.3"}).scheduleValidate();
    packagesDir({"foo": "1.2.3"}).scheduleValidate();
  });
}
