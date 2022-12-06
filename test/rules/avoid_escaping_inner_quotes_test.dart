// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidEscapingInnerQuotesTest);
  });
}

@reflectiveTest
class AvoidEscapingInnerQuotesTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_escaping_inner_quotes';

  test_singleQuotes() async {
    await assertDiagnostics(r'''
void f(String d) {
  print('a\'b\'c ${d.length}');
}
''', [
      lint(27, 21),
    ]);
  }
}
