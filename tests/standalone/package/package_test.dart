// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Packages=none

library package_test;

import "package:expect/expect.dart";

import 'package:lib1/lib1.dart';
import 'package:shared/shared.dart';

void main() {
  output = 'main';
  // Call an imported lib, which will in turn call some others.
  lib1();

  // Make sure they were all reached successfully.
  Expect.equals('main|lib1|lib2|lib3', output);
}
