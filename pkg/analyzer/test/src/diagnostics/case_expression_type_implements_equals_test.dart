// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(CaseExpressionTypeImplementsEqualsTest);
  });
}

@reflectiveTest
class CaseExpressionTypeImplementsEqualsTest extends DriverResolutionTest {
  test_declares() async {
    await assertNoErrorsInCode(r'''
print(p) {}

abstract class B {
  final id;
  const B(this.id);
  String toString() => 'C($id)';
  /** Equality is identity equality, the id isn't used. */
  bool operator==(Object other);
  }

class C extends B {
  const C(id) : super(id);
}

void doSwitch(c) {
  switch (c) {
  case const C(0): print('Switch: 0'); break;
  case const C(1): print('Switch: 1'); break;
  }
}
''');
  }

  test_implements() async {
    await assertErrorsInCode(r'''
class IntWrapper {
  final int value;
  const IntWrapper(this.value);
  bool operator ==(Object x) {
    return x is IntWrapper && x.value == value;
  }
  get hashCode => value;
}

f(var a) {
  switch(a) {
    case(const IntWrapper(1)) : return 1;
    default: return 0;
  }
}
''', [
      error(
          CompileTimeErrorCode.CASE_EXPRESSION_TYPE_IMPLEMENTS_EQUALS, 194, 6),
    ]);
  }

  test_int() async {
    await assertNoErrorsInCode(r'''
f(int i) {
  switch(i) {
    case(1) : return 1;
    default: return 0;
  }
}
''');
  }

  test_Object() async {
    await assertNoErrorsInCode(r'''
class IntWrapper {
  final int value;
  const IntWrapper(this.value);
}

f(IntWrapper intWrapper) {
  switch(intWrapper) {
    case(const IntWrapper(1)) : return 1;
    default: return 0;
  }
}
''');
  }

  test_String() async {
    await assertNoErrorsInCode(r'''
f(String s) {
  switch(s) {
    case('1') : return 1;
    default: return 0;
  }
}
''');
  }
}
