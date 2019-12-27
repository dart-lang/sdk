// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAliasCannotReferenceItselfTest);
  });
}

@reflectiveTest
class TypeAliasCannotReferenceItselfTest extends DriverResolutionTest {
  test_functionTypedParameter_returnType() async {
    await assertErrorsInCode('''
typedef A(A b());
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 17),
    ]);
  }

  test_generic() async {
    await assertErrorsInCode(r'''
typedef F = void Function(List<G> l);
typedef G = void Function(List<F> l);
main() {
  F foo(G g) => g;
  foo(null);
}
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 37),
      error(StaticTypeWarningCode.RETURN_OF_INVALID_TYPE_FROM_FUNCTION, 101, 1),
    ]);
  }

  test_infiniteParameterBoundCycle() async {
    await assertErrorsInCode(r'''
typedef F<X extends F> = F Function();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 38),
      error(StrongModeCode.NOT_INSTANTIATED_BOUND, 20, 1),
    ]);
  }

  test_issue11987() async {
    await assertErrorsInCode(r'''
typedef void F(List<G> l);
typedef void G(List<F> l);
main() {
  F foo(G g) => g;
  foo(null);
}
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 26),
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 27, 26),
    ]);
  }

  test_issue19459() async {
    // A complex example involving multiple classes.  This is legal, since
    // typedef F references itself only via a class.
    await assertNoErrorsInCode(r'''
class A<B, C> {}
abstract class D {
  f(E e);
}
abstract class E extends A<dynamic, F> {}
typedef D F();
''');
  }

  test_parameterType_named() async {
    await assertErrorsInCode('''
typedef A({A a});
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 17),
    ]);
  }

  test_parameterType_positional() async {
    await assertErrorsInCode('''
typedef A([A a]);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 17),
    ]);
  }

  test_parameterType_required() async {
    await assertErrorsInCode('''
typedef A(A a);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 15),
    ]);
  }

  test_parameterType_typeArgument() async {
    await assertErrorsInCode('''
typedef A(List<A> a);
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 21),
    ]);
  }

  test_referencesReturnType_inTypeAlias() async {
    await assertNoErrorsInCode(r'''
typedef B A();
class B {
  A a;
}
''');
  }

  test_returnClass_withTypeAlias() async {
    // A typedef is allowed to indirectly reference itself via a class.
    await assertNoErrorsInCode(r'''
typedef C A();
typedef A B();
class C {
  B a;
}
''');
  }

  test_returnType() async {
    await assertErrorsInCode('''
typedef A A();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 14),
    ]);
  }

  test_returnType_indirect() async {
    await assertErrorsInCode(r'''
typedef B A();
typedef A B();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 14),
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 15, 14),
    ]);
  }

  test_typeVariableBounds() async {
    await assertErrorsInCode('''
typedef A<T extends A<int>>();
''', [
      error(CompileTimeErrorCode.TYPE_ALIAS_CANNOT_REFERENCE_ITSELF, 0, 30),
      error(CompileTimeErrorCode.TYPE_ARGUMENT_NOT_MATCHING_BOUNDS, 22, 3),
    ]);
  }
}
