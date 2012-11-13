// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('updates a locked pub server package with a new incompatible '
      'constraint', () {
    servePackages([package("foo", "1.0.0")]);

    appDir([dependency("foo")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    packagesDir({"foo": "1.0.0"}).scheduleValidate();

    servePackages([package("foo", "1.0.1")]);

    appDir([dependency("foo", ">1.0.0")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp(r"Dependencies installed!$"));

    packagesDir({"foo": "1.0.1"}).scheduleValidate();

    run();
  });
}
