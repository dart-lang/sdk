// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub_tests;

import 'dart:io';

import '../../test_pub.dart';
import '../../../../../pkg/unittest/lib/unittest.dart';

main() {
  test('checks out a package from a pub server', () {
    servePackages([package("foo", "1.2.3")]);

    appDir([dependency("foo", "1.2.3")]).scheduleCreate();

    schedulePub(args: ['install'],
        output: const RegExp("Dependencies installed!\$"));

    cacheDir({"foo": "1.2.3"}).scheduleValidate();
    packagesDir({"foo": "1.2.3"}).scheduleValidate();

    run();
  });
}
