// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotInstantiatedBoundTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NotInstantiatedBoundTest extends PubPackageResolutionTest {
  test_argument_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V extends List<K>> {}
class C<T extends A> {}
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_argumentDeep_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V extends List<List<K>>> {}
class C<T extends A> {}
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_class_bound_argument_instantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
class B<T extends int> {}
class C<T extends A<B>> {}
''');
  }

  test_class_bound_argument_recursive_instantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V> {}
class B<T extends int> {}
class C<T extends A<B, B>> {}
''');
  }

  test_class_bound_bound_instantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
class C<T extends A<int>> {}
class D<T extends C> {}
''');
  }

  test_class_function_instantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends void Function()> {}
class B<T extends A> {}
''');
  }

  test_class_instantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends int> {}
class C1<T extends A> {}
class C2<T extends List<A>> {}
''');
  }

  test_class_recursion_boundArgument_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends B<A>> {}
//                  ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
class B<T extends A<B>> {}
//                  ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_class_recursion_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends B> {} // points to a
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
class B<T extends A> {} // points to b
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
class C<T extends A> {} // points to a cyclical type
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_class_recursion_notInstantiated_genericFunctionType() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends void Function(A)> {}
//                              ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_class_recursion_notInstantiated_genericFunctionType2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends void Function<U extends A>()> {}
//                                        ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_class_recursion_typedef_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef F(C value);
//      ^
// [diag.typeAliasCannotReferenceItself] Typedefs can't reference themselves directly or recursively via another typedef.
class C<T extends F> {}
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
class D<T extends C> {}
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_class_typedef_instantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef void F<T extends int>();
class C<T extends F> {}
''');
  }

  test_direct_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V extends K> {}
class C<T extends A> {}
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_functionType_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends Function(T)> {}
class B<T extends T Function()> {}
class C<T extends A> {}
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
class D<T extends B> {}
//                ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_indirect_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V extends K> {}
class C<T extends List<A>> {}
//                     ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_typedef_argument_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V extends List<K>> {}
typedef void F<T extends A>();
//                       ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_typedef_argumentDeep_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V extends List<List<K>>> {}
typedef void F<T extends A>();
//                       ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }

  test_typedef_class_instantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class C<T extends int> {}
typedef void F<T extends C>();
''');
  }

  test_typedef_direct_notInstantiated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<K, V extends K> {}
typedef void F<T extends A>();
//                       ^
// [diag.notInstantiatedBound] Type parameter bound types must be instantiated.
''');
  }
}
