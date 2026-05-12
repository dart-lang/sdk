// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AbstractFieldInitializerTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AbstractFieldInitializerTest extends PubPackageResolutionTest {
  test_abstract_field_final_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract final int x = 0;
//                   ^
// [diag.abstractFieldInitializer] Abstract fields can't have initializers.
}
''');
  }

  test_abstract_field_final_no_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract final int x;
}
''');
  }

  test_abstract_field_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int x = 0;
//             ^
// [diag.abstractFieldInitializer] Abstract fields can't have initializers.
}
''');
  }

  test_abstract_field_no_initializer() async {
    await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  abstract int x;
}
''');
  }
}
