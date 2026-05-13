// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresAbstractMethodTest);
  });
}

@reflectiveTest
class ExtensionDeclaresAbstractMethodTest extends PubPackageResolutionTest {
  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  bool get isPalindrome;
//         ^^^^^^^^^^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  String reversed();
//       ^^^^^^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_none() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {}
''');
  }

  test_operator() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  String operator -(String otherString);
//                ^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  set length(int newLength);
//    ^^^^^^
// [diag.extensionDeclaresAbstractMember] Extensions can't declare abstract members.
}
''');
  }
}
