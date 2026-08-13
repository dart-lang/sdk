// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAliasCannotReferenceItselfTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeAliasCannotReferenceItselfTest extends PubPackageResolutionTest {
  test_functionTypeAlias_typeParameterBounds() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<T extends A<int>>();
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_functionTypedParameter_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A(A b());
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = void Function(List<G> l);
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
typedef G = void Function(List<F> l);
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
main() {
  F? foo(G? g) => g;
  foo(null);
}
''');
  }

  test_genericTypeAlias_typeParameterBounds() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A<T extends A<int>> = void Function();
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_infiniteParameterBoundCycle() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F<X extends F<X>> = F Function();
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_issue11987() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void F(List<G> l);
//           ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
typedef void G(List<F> l);
//           ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
main() {
  F? foo(G? g) => g;
  foo(null);
}
''');
  }

  test_issue19459() async {
    // A complex example involving multiple classes.  This is legal, since
    // typedef F references itself only via a class.
    await resolveTestCodeWithDiagnostics(r'''
class A<B, C> {}
abstract class D {
  f(E e);
}
abstract class E extends A<dynamic, F> {}
typedef D F();
''');
  }

  test_nonFunction_aliasedType_cycleOf2() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T1 = T2;
//      ^^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
typedef T2 = T1;
//      ^^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_nonFunction_aliasedType_directly_functionWithIt() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T = void Function(T);
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_nonFunction_aliasedType_directly_it_none() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T = T;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_nonFunction_aliasedType_directly_it_question() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T = T?;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_nonFunction_aliasedType_directly_ListOfIt() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T = List<T>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_nonFunction_typeParameterBounds() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef T<X extends T<Never>> = List<X>;
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_parameterType_named() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A({A a});
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_parameterType_positional() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A([A a]);
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_parameterType_required() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A(A a);
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_parameterType_typeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A(List<A> a);
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_referencesReturnType_inTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef B A();
class B {
  A? a;
}
''');
  }

  test_returnClass_withTypeAlias() async {
    // A typedef is allowed to indirectly reference itself via a class.
    await resolveTestCodeWithDiagnostics(r'''
typedef C A();
typedef A B();
class C {
  B? a;
}
''');
  }

  test_returnType() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A A();
//        ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_returnType_indirect() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef B A();
//        ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
typedef A B();
//        ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }

  test_usingRecordType_directly() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F = (F, int) Function();
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
''');
  }
}
