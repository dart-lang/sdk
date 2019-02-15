// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UndefinedOperatorTest);
  });
}

@reflectiveTest
class UndefinedOperatorTest extends DriverResolutionTest {
  test_binaryExpression() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a + 1;
  }
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_binaryExpression_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator +(B b) {}
}
f(var a) {
  if (a is A) {
    a + 1;
  }
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_indexBoth() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a[0]++;
  }
}
''', [
      StaticTypeWarningCode.UNDEFINED_OPERATOR,
      StaticTypeWarningCode.UNDEFINED_OPERATOR,
    ]);
  }

  test_indexBoth_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator [](int index) {}
}
f(var a) {
  if (a is A) {
    a[0]++;
  }
}
''', [
      StaticTypeWarningCode.UNDEFINED_OPERATOR,
      StaticTypeWarningCode.UNDEFINED_OPERATOR,
    ]);
  }

  test_indexGetter() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a[0];
  }
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_indexGetter_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator [](int index) {}
}
f(var a) {
  if (a is A) {
    a[0];
  }
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_indexSetter() async {
    await assertErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a[0] = 1;
  }
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_indexSetter_inSubtype() async {
    await assertErrorsInCode(r'''
class A {}
class B extends A {
  operator []=(i, v) {}
}
f(var a) {
  if (a is A) {
    a[0] = 1;
  }
}
''', [StaticTypeWarningCode.UNDEFINED_OPERATOR]);
  }

  test_postfixExpression() async {
    await assertNoErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    a++;
  }
}
''');
  }

  test_postfixExpression_inSubtype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if (a is A) {
    a++;
  }
}
''');
  }

  test_prefixExpression() async {
    await assertNoErrorsInCode(r'''
class A {}
f(var a) {
  if (a is A) {
    ++a;
  }
}
''');
  }

  test_prefixExpression_inSubtype() async {
    await assertNoErrorsInCode(r'''
class A {}
class B extends A {
  operator +(B b) {return new B();}
}
f(var a) {
  if (a is A) {
    ++a;
  }
}
''');
  }
}
