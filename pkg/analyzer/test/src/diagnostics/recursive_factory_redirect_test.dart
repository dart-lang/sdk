// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecursiveFactoryRedirectTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecursiveFactoryRedirectTest extends PubPackageResolutionTest {
  test_directSelfReference() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() = A;
//              ^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
''');
  }

  test_diverging() async {
    // Analysis should terminate even though the redirections don't reach a
    // fixed point.  (C<int> redirects to C<C<int>>, then to C<C<C<int>>>, and
    // so on).
    await resolveTestCodeWithDiagnostics(r'''
class C<T> {
  const factory C() = C<C<T>>;
//                    ^^^^^^^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
main() {
  const C<int>();
}
''');
  }

  test_generic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A<T> implements B<T> {
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: C, B, A.
  factory A() = C;
//              ^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
class B<T> implements C<T> {
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: C, B, A.
  factory B() = A;
//              ^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
class C<T> implements A<T> {
//    ^
// [diag.recursiveInterfaceInheritance] 'C' can't be a superinterface of itself: C, B, A.
  factory C() = B;
//              ^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
''');
  }

  test_loop() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements B {
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: C, B, A.
  factory A() = C;
//              ^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
class B implements C {
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: C, B, A.
  factory B() = A;
//              ^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
class C implements A {
//    ^
// [diag.recursiveInterfaceInheritance] 'C' can't be a superinterface of itself: C, B, A.
  factory C() = B;
//              ^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
''');
  }

  test_named() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements B {
//    ^
// [diag.recursiveInterfaceInheritance] 'A' can't be a superinterface of itself: C, B, A.
  factory A.nameA() = C.nameC;
//                    ^^^^^^^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
class B implements C {
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: C, B, A.
  factory B.nameB() = A.nameA;
//                    ^^^^^^^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
class C implements A {
//    ^
// [diag.recursiveInterfaceInheritance] 'C' can't be a superinterface of itself: C, B, A.
  factory C.nameC() = B.nameB;
//                    ^^^^^^^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
''');
  }

  test_outsideCycle() async {
    // "A" references "C" which has cycle with "B". But we should not report
    // problem for "A" - it is not the part of a cycle.
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() = C;
//              ^
// [diag.redirectToInvalidReturnType] The return type 'C' of the redirected constructor isn't a subtype of 'A'.
}
class B implements C {
//    ^
// [diag.recursiveInterfaceInheritance] 'B' can't be a superinterface of itself: C, B.
  factory B() = C;
//              ^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
class C implements A, B {
//    ^
// [diag.recursiveInterfaceInheritance] 'C' can't be a superinterface of itself: C, B.
  factory C() = B;
//              ^
// [diag.recursiveFactoryRedirect] Constructors can't redirect to themselves either directly or indirectly.
}
''');
  }

  test_valid_redirect() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A() = B;
}
class B implements A {
  factory B() = C;
}
class C implements B {
  factory C() => throw 0;
}
''');
  }
}
