// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractFieldConstructorInitializerTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AbstractFieldConstructorInitializerTest extends PubPackageResolutionTest {
  test_abstract_field_constructor_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int x;
  A() : x = 0;
//      ^
// [diag.abstractFieldConstructorInitializer] Abstract fields can't have initializers.
}
''');
  }

  test_abstract_field_final_constructor_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract final int x;
  A() : x = 0;
//      ^
// [diag.abstractFieldConstructorInitializer] Abstract fields can't have initializers.
}
''');
  }

  test_abstract_field_final_initializing_formal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract final int x;
  A(this.x);
//       ^
// [diag.abstractFieldConstructorInitializer] Abstract fields can't have initializers.
}
''');
  }

  test_abstract_field_final_no_initialization() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract final int x;
  A();
}
''');
  }

  test_abstract_field_initializing_formal() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int x;
  A(this.x);
//       ^
// [diag.abstractFieldConstructorInitializer] Abstract fields can't have initializers.
}
''');
  }

  test_abstract_field_no_initialization() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int x;
  A();
}
''');
  }
}
