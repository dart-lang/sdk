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
  Expect.throws(() => a.lateFinalField);
  Expect.equals(5, a.lateFinalField);
  Expect.equals(123, A.staticLateField);
  Expect.throws(() => A.staticLateFinalField);
  Expect.equals(5, A.staticLateFinalField);
}

lateFieldWithComplicatedInitializers() {
  late int count = 0;
  int closure() {
    ++count;
    return 5;
  }

  late int nestedLateVar = closure();
  late var lateVar = [for (int i = 0; i < nestedLateVar; ++i) i * i];
  Expect.equals(0, count);
  Expect.listEquals([0, 1, 4, 9, 16], lateVar);
  Expect.equals(1, count);
  Expect.listEquals([0, 1, 4, 9, 16], lateVar);
  Expect.equals(1, count);
  count = 0;

  late var lateVarInIf = [++count, for (int i = 0; i < 3; ++i) i * i];
  Expect.equals(0, count);
  if (true) Expect.listEquals([1, 0, 1, 4], lateVarInIf);
  Expect.equals(1, count);
  Expect.listEquals([1, 0, 1, 4], lateVarInIf);
  Expect.equals(1, count);
  count = 0;

  late var lateVarInFor = [++count, for (int i = 0; i < 3; ++i) i * i];
  Expect.equals(0, count);
  for (int i = 0; i < 3; ++i) Expect.listEquals([1, 0, 1, 4], lateVarInFor);
  Expect.equals(1, count);
  count = 0;

  late var lateVarInClosure = [++count, for (int i = 0; i < 3; ++i) i * i];
  void anotherClosure() {
    Expect.listEquals([1, 0, 1, 4], lateVarInClosure);
  }

  Expect.equals(0, count);
  anotherClosure();
  anotherClosure();
  anotherClosure();
  Expect.equals(1, count);
  count = 0;

  late int lateVarClosureOuter = () {
    Expect.equals(0, count);
    ++count;
    late int lateVarClosureInner = closure();
    Expect.equals(1, count);
    Expect.equals(5, lateVarClosureInner);
    Expect.equals(2, count);
    return lateVarClosureInner;
  }();
  Expect.equals(0, count);
  Expect.equals(5, lateVarClosureOuter);
  Expect.equals(2, count);
}

class B {
  late int throwBeforeWrite = initThrowBeforeWrite();
  int initThrowBeforeWrite() {
    throw AssertionError();
    return 123;
  }

  late int throwAfterWrite = initThrowAfterWrite();
  int initThrowAfterWrite() {
    throwAfterWrite = 456;
    throw AssertionError();
    return 123;
  }
}

lateFieldWithThrowingInitializers() {
  late int throwBeforeWrite = () {
    throw AssertionError();
    return 123;
  }();
  Expect.throwsAssertionError(() => throwBeforeWrite);
  Expect.throwsAssertionError(() => throwBeforeWrite);
  Expect.throwsAssertionError(() => throwBeforeWrite);

  B b = B();
  Expect.throwsAssertionError(() => b.throwBeforeWrite);
  Expect.throwsAssertionError(() => b.throwBeforeWrite);
  Expect.throwsAssertionError(() => b.throwBeforeWrite);

  Expect.throwsAssertionError(() => b.throwAfterWrite);
  Expect.equals(456, b.throwAfterWrite);
  Expect.equals(456, b.throwAfterWrite);
}

main() {
  lateFieldWithInitThatWritesIntermediateValue();
  lateFieldWithComplicatedInitializers();
  lateFieldWithThrowingInitializers();
}
