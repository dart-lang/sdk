// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NoDefaultSuperConstructorExplicitTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NoDefaultSuperConstructorExplicitTest extends PubPackageResolutionTest {
  test_requiredNamed_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.16
class A {
  A({required int a});
}
class B extends A {
  B.foo();
//^^^^^
// [diag.noDefaultSuperConstructorExplicit] The superclass 'A' doesn't have a zero argument constructor.
}
''');
  }

  test_requiredPositional_constructor_typeName() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.16
class A {
  A(int a);
}
class B extends A {
  B.foo();
//^^^^^
// [diag.noDefaultSuperConstructorExplicit] The superclass 'A' doesn't have a zero argument constructor.
}
''');
  }
}
