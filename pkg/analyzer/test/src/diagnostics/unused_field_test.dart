// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedFieldTest);
  });
}

@reflectiveTest
class UnusedFieldTest extends DriverResolutionTest {
  @override
  bool get enableUnusedElement => true;

  test_unusedField_isUsed_argument() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    print(++_f);
  }
}
print(x) {}
''');
  }

  test_unusedField_isUsed_reference_implicitThis() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
  main() {
    print(_f);
  }
}
print(x) {}
''');
  }

  test_unusedField_isUsed_reference_implicitThis_expressionFunctionBody() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
  m() => _f;
}
''');
  }

  test_unusedField_isUsed_reference_implicitThis_subclass() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
  main() {
    print(_f);
  }
}
class B extends A {
  int _f;
}
print(x) {}
''');
  }

  test_unusedField_isUsed_reference_qualified_propagatedElement() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
}
main() {
  var a = new A();
  print(a._f);
}
print(x) {}
''');
  }

  test_unusedField_isUsed_reference_qualified_staticElement() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
}
main() {
  A a = new A();
  print(a._f);
}
print(x) {}
''');
  }

  test_unusedField_isUsed_reference_qualified_unresolved() async {
    await assertNoErrorsInCode(r'''
class A {
  int _f;
}
main(a) {
  print(a._f);
}
print(x) {}
''');
  }

  test_unusedField_notUsed_compoundAssign() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  main() {
    _f += 2;
  }
}
''', [HintCode.UNUSED_FIELD]);
  }

  test_unusedField_notUsed_constructorFieldInitializers() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  A() : _f = 0;
}
''', [HintCode.UNUSED_FIELD]);
  }

  test_unusedField_notUsed_fieldFormalParameter() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  A(this._f);
}
''', [HintCode.UNUSED_FIELD]);
  }

  test_unusedField_notUsed_noReference() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
}
''', [HintCode.UNUSED_FIELD]);
  }

  test_unusedField_notUsed_nullAssign() async {
    await assertNoErrorsInCode(r'''
class A {
  var _f;
  m() {
    _f ??= doSomething();
  }
}
doSomething() => 0;
''');
  }

  test_unusedField_notUsed_postfixExpr() async {
    await assertErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    _f++;
  }
}
''', [HintCode.UNUSED_FIELD]);
  }

  test_unusedField_notUsed_prefixExpr() async {
    await assertErrorsInCode(r'''
class A {
  int _f = 0;
  main() {
    ++_f;
  }
}
''', [HintCode.UNUSED_FIELD]);
  }

  test_unusedField_notUsed_simpleAssignment() async {
    await assertErrorsInCode(r'''
class A {
  int _f;
  m() {
    _f = 1;
  }
}
main(A a) {
  a._f = 2;
}
''', [HintCode.UNUSED_FIELD]);
  }
}
