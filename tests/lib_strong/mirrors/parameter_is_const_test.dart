// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.parameter_is_const;

import 'dart:mirrors';

import 'package:expect/expect.dart';

class Class {
  foo(
  const //# 01: compile-time error
      param) {}
}

main() {
  MethodMirror mm = reflectClass(Class).declarations[#foo];
  Expect.isFalse(mm.parameters.single.isConst);
}
