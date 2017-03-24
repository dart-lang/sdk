// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that constant local variables have constant initializers.

import "package:expect/expect.dart";

void main() {
  const c1; //# 01: compile-time error
  const c2 = 0;
  const c3 = field; //# 02: compile-time error
  const c4 = finalField; //# 03: compile-time error
  const c5 = constField;
  const c6 = method(); //# 04: compile-time error
  const c7 = new Class(); //# 05: compile-time error
  const c8 = const Class();
}

var field = 0;

final finalField = 0;

const constField = 0;

method() => 0;

class Class {
  const Class();
}
