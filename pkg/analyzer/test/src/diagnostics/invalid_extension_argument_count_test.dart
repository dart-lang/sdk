// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidExtensionArgumentCountTest);
  });
}

@reflectiveTest
class InvalidExtensionArgumentCountTest extends PubPackageResolutionTest {
  test_many() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  void m() {}
}
f() {
  E('a', 'b', 'c').m();
// ^^^^^^^^^^^^^^^
// [diag.invalidExtensionArgumentCount] Extension overrides must have exactly one argument: the value of 'this' in the extension method.
}
''');
    assertTypeDynamic(result.findNode.extensionOverride('E(').extendedType);
  }

  test_one() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  void m() {}
}
f() {
  E('a').m();
}
''');
  }

  test_zero() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  void m() {}
}
f() {
  E().m();
// ^^
// [diag.invalidExtensionArgumentCount] Extension overrides must have exactly one argument: the value of 'this' in the extension method.
}
''');
    assertTypeDynamic(result.findNode.extensionOverride('E(').extendedType);
  }
}
