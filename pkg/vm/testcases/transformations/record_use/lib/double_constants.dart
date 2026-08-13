// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;
import 'package:meta/meta.dart' show RecordUse;

const negativeZero = -0.0;
const minPositive = 5e-324;
const minusMinPositive = -minPositive;
const highPrecision = 0.12345678901234567;

void main() {
  print(SomeClass.someStaticMethod(1.234));
  print(SomeClass.someStaticMethod(double.infinity));
  print(SomeClass.someStaticMethod(double.negativeInfinity));
  print(SomeClass.someStaticMethod(double.nan));
  print(SomeClass.someStaticMethod(negativeZero));

  print(SomeClass.someStaticMethod(minPositive));
  print(SomeClass.someStaticMethod(minusMinPositive));

  print(SomeClass.someStaticMethod(highPrecision));
  print(SomeClass.someStaticMethod(math.pi));
}

class SomeClass {
  @RecordUse()
  static String someStaticMethod(double d) => d.toString();
}
