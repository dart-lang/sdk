// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidPrivateTypedefFunctionsTest);
  });
}

@reflectiveTest
class AvoidPrivateTypedefFunctionsTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_private_typedef_functions';

  test_nonFunctionTypeAlias() async {
    await assertNoDiagnostics(r'''
// ignore: unused_element
typedef _td = List<String>;
''');
  }
}
