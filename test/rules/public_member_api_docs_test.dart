// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PublicMemberApiDocsTest);
  });
}

@reflectiveTest
class PublicMemberApiDocsTest extends LintRuleTest {
  @override
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'public_member_api_docs';

  test_enum() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  int x() => 0;
  int get y => 1;
}
''', [
      lint('public_member_api_docs', 5, 1),
      lint('public_member_api_docs', 11, 1),
      lint('public_member_api_docs', 13, 1),
      lint('public_member_api_docs', 15, 1),
      lint('public_member_api_docs', 24, 1),
      lint('public_member_api_docs', 44, 1),
    ]);
  }
}
