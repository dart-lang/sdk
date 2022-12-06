// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidVoidAsyncTest);
  });
}

@reflectiveTest
class AvoidVoidAsyncTest extends LintRuleTest {
  @override
  String get lintRule => 'avoid_void_async ';

  test_main() async {
    await assertNoDiagnostics(r'''
Future<void> f() async { }
void main() async { 
  await f();
}
''');
  }
}
