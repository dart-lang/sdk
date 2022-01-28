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
  List<String> get experiments => [
        EnableString.enhanced_enums,
      ];

  @override
  String get lintRule => 'hash_and_equals';

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3195')
  test_enum_missingHash() async {
    await assertDiagnostics(r'''
enum A {
  a,b,c;
  @override
  bool operator ==(Object other) => false;
}
''', [
      lint('hash_and_equals', 46, 2), // todo(pq): fix index
    ]);
  }
}
