// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library barback.test.barback_mode_test;

import 'package:barback/barback.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  initConfig();
  test("constructor uses canonical instances for DEBUG and RELEASE", () {
    expect(identical(BarbackMode.DEBUG,
        new BarbackMode(BarbackMode.DEBUG.name)), isTrue);
    expect(identical(BarbackMode.RELEASE,
        new BarbackMode(BarbackMode.RELEASE.name)), isTrue);
  });
}
