// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonFinalFieldInEnumTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class NonFinalFieldInEnumTest extends PubPackageResolutionTest {
  test_declaringFormalParameter_optionalNamed_typeInt_final() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E({final int foo = 0}) {
  v(foo: 0);
}
''');
  }

  test_declaringFormalParameter_optionalNamed_typeInt_var() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E({var int foo = 0}) {
//              ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
  v(foo: 0);
}
''');
  }

  test_declaringFormalParameter_optionalPositional_typeInt_final() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E([final int foo = 0]) {
  v(0);
}
''');
  }

  test_declaringFormalParameter_optionalPositional_typeInt_var() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E([var int foo = 0]) {
//              ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
  v(0);
}
''');
  }

  test_declaringFormalParameter_requiredNamed_typeInt_final() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E({required final int foo}) {
  v(foo: 0);
}
''');
  }

  test_declaringFormalParameter_requiredNamed_typeInt_var() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E({required var int foo}) {
//                       ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
  v(foo: 0);
}
''');
  }

  test_declaringFormalParameter_requiredPositional_functionTyped_final() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(final void foo()?) {
  v(null);
}
''');
  }

  test_declaringFormalParameter_requiredPositional_functionTyped_var() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(var void foo()?) {
//              ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
  v(null);
}
''');
  }

  test_declaringFormalParameter_requiredPositional_typeInt_final() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(final int foo) {
  v(0);
}
''');
  }

  test_declaringFormalParameter_requiredPositional_typeInt_var() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E(var int foo) {
//             ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
  v(0);
}
''');
  }

  test_fieldDeclaration_instance() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int foo = 0;
//    ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
}
''');
  }

  test_fieldDeclaration_instance_covariant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  covariant int foo = 0;
//              ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
}
''');
  }

  test_fieldDeclaration_instance_external() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external int foo;
}
''');
  }

  test_fieldDeclaration_instance_external_final() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  external final int foo;
}
''');
  }

  test_fieldDeclaration_instance_final() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int foo = 0;
}
''');
  }

  test_fieldDeclaration_instance_late() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  late int foo = 0;
//         ^^^
// [diag.nonFinalFieldInEnum] Enums can only declare final fields.
}
''');
  }

  test_fieldDeclaration_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int foo = 0;
}
''');
  }

  test_fieldDeclaration_static_final() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static final int foo = 0;
}
''');
  }
}
