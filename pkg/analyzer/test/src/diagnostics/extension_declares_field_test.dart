// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresFieldTest);
  });
}

@reflectiveTest
class ExtensionDeclaresFieldTest extends PubPackageResolutionTest {
  test_instanceField1_final_late_typeInt() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  late final int v;
//               ^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_instanceField1_typeIntQ() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int? v;
//     ^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_instanceField3_typeIntQ() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int? v1, v2;
//     ^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
//         ^^
// [diag.extensionDeclaresInstanceField] Extensions can't declare instance fields.
}
''');
  }

  test_none() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {}
''');
  }

  test_staticField1_typeInt() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  static int v = 0;
}
''');
  }
}
