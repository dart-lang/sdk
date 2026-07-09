// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresConstructorTest);
  });
}

@reflectiveTest
class ExtensionDeclaresConstructorTest extends PubPackageResolutionTest {
  test_named() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  E.named() : super();
//^
// [diag.extensionDeclaresConstructor] Extensions can't declare constructors.
}
''');
  }

  test_none() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {}
''');
  }

  test_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  E() : super();
//^
// [diag.extensionDeclaresConstructor] Extensions can't declare constructors.
}
''');
  }
}
