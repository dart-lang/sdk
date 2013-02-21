// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';

main() {
  initConfig();
  integration('installs a package from a pub server', () {
    servePackages([package("foo", "1.2.3")]);

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: new RegExp("Dependencies installed!\$"));

    cacheDir({"foo": "1.2.3"}).scheduleValidate();
    packagesDir({"foo": "1.2.3"}).scheduleValidate();
  });

  integration('URL encodes the package name', () {
    servePackages([]);

    appDir([dependency("bad name!", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['install'],
        error: new RegExp('Could not find package "bad name!" at '
                          'http://localhost:'),
        exitCode: 1);
  });
}
