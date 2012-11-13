// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('keeps a pub server package locked to the version in the lockfile', () {
    servePackages([package("foo", "1.0.0")]);

    appDir([dependency("foo")]).scheduleCreate();

    // This install should lock the foo dependency to version 1.0.0.
    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    packagesDir({"foo": "1.0.0"}).scheduleValidate();

    // Delete the packages path to simulate a new checkout of the application.
    dir(packagesPath).scheduleDelete();

    // Start serving a newer package as well.
    servePackages([package("foo", "1.0.1")]);

    // This install shouldn't update the foo dependency due to the lockfile.
    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    packagesDir({"foo": "1.0.0"}).scheduleValidate();

    run();
  });
}
