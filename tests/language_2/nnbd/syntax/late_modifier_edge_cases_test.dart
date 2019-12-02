// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable
import 'package:expect/expect.dart';

class A {
  late int lateField = initLateField();

  int initLateField() {
    lateField = 456;
    Expect.equals(456, lateField);
    return 123;
  }

  late final int lateFinalField = initLateFinalField();

  int count = 0;
  int initLateFinalField() {
    if (count == 5) return count;
    return ++count + lateFinalField;
  }

  static late int staticLateField = initStaticLateField();

  static int initStaticLateField() {
    staticLateField = 456;
    Expect.equals(456, staticLateField);
    return 123;
  }

  static late final int staticLateFinalField = initStaticLateFinalField();

  static int staticCount = 0;
  static int initStaticLateFinalField() {
    if (staticCount == 5) return staticCount;
    return ++staticCount + staticLateFinalField;
  }
}

lateFieldWithInitThatWritesIntermediateValue() {
  A a = A();
  Expect.equals(123, a.lateField);
  Expect.throws(() => print(a.lateFinalField));
  Expect.equals(5, a.lateFinalField);
  Expect.equals(123, A.staticLateField);
  Expect.throws(() => print(A.staticLateFinalField));
  Expect.equals(5, A.staticLateFinalField);
}

main() {
  lateFieldWithInitThatWritesIntermediateValue();
}
