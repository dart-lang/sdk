// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AugmentationVariableDifferentGetterSetterTypesTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AugmentationVariableDifferentGetterSetterTypesTest
    extends PubPackageResolutionTest {
  test_class_instanceGetterSetter_different() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
  set foo(String _) {}
  augment abstract var foo;
//                     ^^^
// [diag.augmentationVariableDifferentGetterSetterTypes] The getter and setter augmented by this variable have different types: 'int' and 'String'.
}
''');
  }

  test_class_instanceGetterSetter_same() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int get foo => 0;
  set foo(int _) {}
  augment abstract var foo;
}
''');
  }

  test_topLevelGetterSetter_different() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

set foo(String _) {}

augment abstract var foo;
//                   ^^^
// [diag.augmentationVariableDifferentGetterSetterTypes] The getter and setter augmented by this variable have different types: 'int' and 'String'.
''');
  }

  test_topLevelGetterSetter_same() async {
    await resolveTestCodeWithDiagnostics(r'''
int get foo => 0;

set foo(int _) {}

augment abstract var foo;
''');
  }

  test_topLevelGetterSetter_same_viaTypeAlias() async {
    await resolveTestCodeWithDiagnostics(r'''
typedef A = int;

int get foo => 0;

set foo(A _) {}

augment abstract var foo;
''');
  }
}
