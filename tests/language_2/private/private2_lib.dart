// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing access to private fields across class hierarchies.

// @dart = 2.9

library Private2Lib;

import "private2_test.dart";

class B extends A {
  B() : super();
}
