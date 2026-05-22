// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideWithCascadeTest);
  });
}

@reflectiveTest
class ExtensionOverrideWithCascadeTest extends PubPackageResolutionTest {
  test_getter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  int get g => 0;
}
f() {
  E(3)..g..g;
//^
// [diag.extensionOverrideWithCascade] Extension overrides have no value so they can't be used as the receiver of a cascade expression.
}
''');
    assertTypeDynamic(result.findNode.extensionOverride('E('));
  }

  test_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  void m() {}
}
f() {
  E(3)..m()..m();
//^
// [diag.extensionOverrideWithCascade] Extension overrides have no value so they can't be used as the receiver of a cascade expression.
}
''');
    assertTypeDynamic(result.findNode.extensionOverride('E('));
  }

  test_setter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension E on int {
  set s(int i) {}
}
f() {
  E(3)..s = 1..s = 2;
//^
// [diag.extensionOverrideWithCascade] Extension overrides have no value so they can't be used as the receiver of a cascade expression.
}
''');
    assertTypeDynamic(result.findNode.extensionOverride('E('));
  }
}
