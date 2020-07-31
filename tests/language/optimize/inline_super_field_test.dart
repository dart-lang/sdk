// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that source maps use the correct compilation unit when super class
// fields from another compilation unit are inlined.

library inline_super_field_test;

import 'package:expect/expect.dart';
import "inline_super_field_lib.dart";

class S {}

class C extends S with M1 {}

void main() {
  var c = new C();
  Expect.equals(1, c.bar);
}
