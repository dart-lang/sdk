// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/resolver_test_case.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMemberUseTest);
    defineReflectiveTests(DeprecatedMemberUseTest_Driver);
  });
}

@reflectiveTest
class DeprecatedMemberUseTest extends ResolverTestCase {
  test__methodInvocation_contructor() async {
    assertErrorsInCode(r'''
class A {
  @Deprecated('0.9')
  m() {}
  n() {m();}
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_call() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  call() {}
  m() {
    A a = new A();
    a();
  }
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_compoundAssignment() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  A operator+(A a) { return a; }
}
f(A a) {
  A b;
  a += b;
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_export() async {
    addNamedSource("/deprecated_library.dart", r'''
@deprecated
library deprecated_library;
class A {}
''');
    assertErrorsInCode('''
export 'deprecated_library.dart';
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_field() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  int x = 1;
}
f(A a) {
  return a.x;
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_getter() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  get m => 1;
}
f(A a) {
  return a.m;
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_import() async {
    addNamedSource("/deprecated_library.dart", r'''
@deprecated
library deprecated_library;
class A {}
''');
    assertErrorsInCode(r'''
import 'deprecated_library.dart';
f(A a) {}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_inDeprecatedClass() async {
    assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
class C {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedField() async {
    assertNoErrorsInCode(r'''
@deprecated
class C {}

class X {
  @deprecated
  C f;
}
''');
  }

  test_inDeprecatedFunction() async {
    assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
g() {
  f();
}
''');
  }

  test_inDeprecatedLibrary() async {
    assertNoErrorsInCode(r'''
@deprecated
library lib;

@deprecated
f() {}

class C {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMethod() async {
    assertNoErrorsInCode(r'''
@deprecated
f() {}

class C {
  @deprecated
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMethod_inDeprecatedClass() async {
    assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
class C {
  @deprecated
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedMixin() async {
    assertNoErrorsInCode(r'''
@deprecated
f() {}

@deprecated
mixin M {
  m() {
    f();
  }
}
''');
  }

  test_inDeprecatedTopLevelVariable() async {
    assertNoErrorsInCode(r'''
@deprecated
class C {}

@deprecated
C v;
''');
  }

  test_indexExpression() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  operator[](int i) {}
}
f(A a) {
  return a[1];
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_instanceCreation_defaultConstructor() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  A(int i) {}
}
f() {
  A a = new A(1);
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_instanceCreation_namedConstructor() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  A.named(int i) {}
}
f() {
  A a = new A.named(1);
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_methodInvocation_constant() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  m() {}
  n() {m();}
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_operator() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  operator+(A a) {}
}
f(A a) {
  A b;
  return a + b;
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_parameter_named() async {
    assertErrorsInCode(r'''
class A {
  m({@deprecated int x}) {}
  n() {m(x: 1);}
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_parameter_named_inDefiningFunction() async {
    assertNoErrorsInCode(r'''
f({@deprecated int x}) => x;
''');
  }

  test_parameter_named_inDefiningLocalFunction() async {
    assertNoErrorsInCode(r'''
class C {
  m() {
    f({@deprecated int x}) {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_named_inDefiningMethod() async {
    assertNoErrorsInCode(r'''
class C {
  m({@deprecated int x}) {
    return x;
  }
}
''');
  }

  test_parameter_named_inNestedLocalFunction() async {
    assertNoErrorsInCode(r'''
class C {
  m({@deprecated int x}) {
    f() {
      return x;
    }
    return f();
  }
}
''');
  }

  test_parameter_positional() async {
    assertErrorsInCode(r'''
class A {
  m([@deprecated int x]) {}
  n() {m(1);}
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_setter() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  set s(v) {}
}
f(A a) {
  return a.s = 1;
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_superConstructor_defaultConstructor() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  A() {}
}
class B extends A {
  B() : super() {}
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }

  test_superConstructor_namedConstructor() async {
    assertErrorsInCode(r'''
class A {
  @deprecated
  A.named() {}
}
class B extends A {
  B() : super.named() {}
}
''', [HintCode.DEPRECATED_MEMBER_USE]);
  }
}

@reflectiveTest
class DeprecatedMemberUseTest_Driver extends DeprecatedMemberUseTest {
  @override
  bool get enableNewAnalysisDriver => true;
}
