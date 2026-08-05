// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FieldInitializingFormalNotAssignableTest);
  });
}

@reflectiveTest
class FieldInitializingFormalNotAssignableTest
    extends PubPackageResolutionTest {
  test_class_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x;
  A(dynamic this.x) {}
//  ^^^^^^^^^^^^^^
// [diag.fieldInitializingFormalNotAssignable] The parameter type 'dynamic' is incompatible with the field type 'int'.
}
''');
  }

  test_class_unrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  int x;
  A(String this.x) {}
//  ^^^^^^^^^^^^^
// [diag.fieldInitializingFormalNotAssignable] The parameter type 'String' is incompatible with the field type 'int'.
}
''');
  }

  test_enum_dynamic() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v(0);
  final int x;
  const E(dynamic this.x);
//        ^^^^^^^^^^^^^^
// [diag.fieldInitializingFormalNotAssignable] The parameter type 'dynamic' is incompatible with the field type 'int'.
}
''');
  }

  test_enum_unrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v('');
//  ^^
// [diag.constConstructorParamTypeMismatch] A value of type 'String' can't be assigned to a parameter of type 'int' in a const constructor.
  final int x;
  const E(String this.x);
//        ^^^^^^^^^^^^^
// [diag.fieldInitializingFormalNotAssignable] The parameter type 'String' is incompatible with the field type 'int'.
}
''');
  }
}
