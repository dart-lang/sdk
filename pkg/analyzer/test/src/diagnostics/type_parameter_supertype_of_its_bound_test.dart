// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeParameterSupertypeOfItsBoundTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeParameterSupertypeOfItsBoundTest extends PubPackageResolutionTest {
  test_1of1() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends T> {
//      ^
// [diag.typeParameterSupertypeOfItsBound] 'T' can't be a supertype of its upper bound.
}
''');
  }

  test_1of1_local() async {
    await resolveTestCodeWithDiagnostics(r'''
void m() {
  void local<T extends T>() {}
//           ^
// [diag.typeParameterSupertypeOfItsBound] 'T' can't be a supertype of its upper bound.
  local;
}
''');
  }

  test_1of1_local_viaExtensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(T it) {}

void m() {
  void local<U extends A<U>>() {}
//           ^
// [diag.typeParameterSupertypeOfItsBound] 'U' can't be a supertype of its upper bound.
  local;
}
''');
  }

  test_1of1_used() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T extends T> {
//      ^
// [diag.typeParameterSupertypeOfItsBound] 'T' can't be a supertype of its upper bound.
  void foo(x) {
    x is T;
  }
}
''');
  }

  test_1of1_viaExtensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(T it) {}

class B<U extends A<U>> {}
//      ^
// [diag.typeParameterSupertypeOfItsBound] 'U' can't be a supertype of its upper bound.
''');
  }

  test_2of2_local_viaExtensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(T it) {}

void m() {
  void local<T1 extends A<T2>, T2 extends T1>() {}
//           ^^
// [diag.typeParameterSupertypeOfItsBound] 'T1' can't be a supertype of its upper bound.
//                             ^^
// [diag.typeParameterSupertypeOfItsBound] 'T2' can't be a supertype of its upper bound.
  local;
}
''');
  }

  test_2of2_viaExtensionType() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(T it) {}

class B<T1 extends A<T2>, T2 extends T1> {}
//      ^^
// [diag.typeParameterSupertypeOfItsBound] 'T1' can't be a supertype of its upper bound.
//                        ^^
// [diag.typeParameterSupertypeOfItsBound] 'T2' can't be a supertype of its upper bound.
''');
  }

  test_2of3() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T1 extends T3, T2, T3 extends T1> {
//      ^^
// [diag.typeParameterSupertypeOfItsBound] 'T1' can't be a supertype of its upper bound.
//                         ^^
// [diag.typeParameterSupertypeOfItsBound] 'T3' can't be a supertype of its upper bound.
}
''');
  }

  test_local_2of3() async {
    await resolveTestCodeWithDiagnostics(r'''
void m() {
  void local<T1 extends T3, T2, T3 extends T1>() {}
//           ^^
// [diag.typeParameterSupertypeOfItsBound] 'T1' can't be a supertype of its upper bound.
//                              ^^
// [diag.typeParameterSupertypeOfItsBound] 'T3' can't be a supertype of its upper bound.
  local;
}
''');
  }
}
