// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ValuesDeclarationInEnumTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ValuesDeclarationInEnumTest extends PubPackageResolutionTest {
  test_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  values
//^^^^^^
// [diag.valuesDeclarationInEnum] A member named 'values' can't be declared in an enum.
}
''');
  }

  test_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final int values = 0;
//          ^^^^^^
// [diag.valuesDeclarationInEnum] A member named 'values' can't be declared in an enum.
}
''');
  }

  test_field_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int values = 0;
//           ^^^^^^
// [diag.valuesDeclarationInEnum] A member named 'values' can't be declared in an enum.
}
''');
  }

  test_field_withConstructor() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  final values = [];
//      ^^^^^^
// [diag.valuesDeclarationInEnum] A member named 'values' can't be declared in an enum.
  const E();
}
''');
  }

  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  int get values => 0;
//        ^^^^^^
// [diag.valuesDeclarationInEnum] A member named 'values' can't be declared in an enum.
}
''');
  }

  test_getter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static int get values => 0;
//               ^^^^^^
// [diag.valuesDeclarationInEnum] A member named 'values' can't be declared in an enum.
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  void values() {}
//     ^^^^^^
// [diag.valuesDeclarationInEnum] A member named 'values' can't be declared in an enum.
}
''');
  }

  test_method_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static void values() {}
//            ^^^^^^
// [diag.valuesDeclarationInEnum] A member named 'values' can't be declared in an enum.
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  set values(_) {}
//    ^^^^^^
// [diag.valuesDeclarationInEnum] A member named 'values' can't be declared in an enum.
}
''');
  }

  test_setter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  static set values(_) {}
}
''');
  }
}
