// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RedirectToAbstractClassConstructorTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RedirectToAbstractClassConstructorTest extends PubPackageResolutionTest {
  test_abstractRedirectsToSelf() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  factory A() = A._;
//              ^^^
// [diag.redirectToAbstractClassConstructor] The redirecting constructor 'A' can't redirect to a constructor of the abstract class 'A'.
  A._();
}
''');
  }

  test_redirectsToAbstractSubclass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A.named() = B;
//                    ^
// [diag.redirectToAbstractClassConstructor] The redirecting constructor 'A.named' can't redirect to a constructor of the abstract class 'B'.
  A();
}

abstract class B extends A {}
''');
  }

  test_redirectsToSubclass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A.named() = B;
  A();
}

class B extends A {}
''');
  }

  test_redirectsToSubclass_asTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  factory A.named() = C;
  A();
}

class B extends A {}
typedef C = B;
''');
  }
}
