// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(HashAndEqualsTest);
  });
}

@reflectiveTest
class HashAndEqualsTest extends LintRuleTest {
  @override
  String get lintRule => 'hash_and_equals';

  test_enum_missingHash() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  @override
  bool operator ==(Object other) => false;
}
''', [
      error(
          CompileTimeErrorCode.ILLEGAL_CONCRETE_ENUM_MEMBER_DECLARATION, 46, 2),
      // no lint
    ]);
  }

  test_extensionType_missingHash() async {
    await assertDiagnostics(r'''
extension type E(Object o) {
  bool operator ==(Object other) => false;
}
''', [
      // No lint.
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT, 45, 2),
    ]);
  }
}
