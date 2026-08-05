// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveInterfaceInheritanceTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveInterfaceInheritanceTest extends PubPackageResolutionTest {
  test_class_extends() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B extends A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
  }

  test_class_extends_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B implements A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
  }

  test_class_implements() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements B {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B implements A {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
  }

  test_class_implements_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> implements B<T> {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B<T> implements A<T> {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
  }

  test_class_implements_generic_typeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> implements B<List<T>> {}
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
class B<T> implements A<List<T>> {}
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
''');
  }

  test_class_implements_tail2() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements B {}
//             ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: B, A.
abstract class B implements A {}
//             ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: B, A.
class C implements A {}
''');
  }

  test_class_implements_tail3() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A implements B {}
//             ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: C, B, A.
abstract class B implements C {}
//             ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: C, B, A.
abstract class C implements A {}
//             ^
// [diag.recursiveInterfaceInheritance] 'C' can't be a superinterface of itself: C, B, A.
class D implements A {}
''');
  }

  test_classTypeAlias_mixin() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin class M1 = Object with M2;
//          ^^
// [diag.recursiveInterfaceInheritance] 'M1' can't be a superinterface of itself: M2, M1.
mixin class M2 = Object with M1;
//          ^^
// [diag.recursiveInterfaceInheritance] 'M2' can't be a superinterface of itself: M2, M1.
''');
  }

  test_classTypeAlias_mixin_superclass() async {
    // Make sure we don't get CompileTimeErrorCode.MIXIN_HAS_NO_CONSTRUCTORS in
    // addition--that would just be confusing.
    await resolveTestCodeWithDiagnostics(r'''
class C = D with M;
//    ^
// [diag.recursiveInterfaceInheritance] 'C' can't be a superinterface of itself: D, C.
class D = C with M;
//    ^
// [diag.recursiveInterfaceInheritance] 'D' can't be a superinterface of itself: D, C.
mixin M {}
''');
  }
}
