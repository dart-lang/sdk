// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DartfixTest);
  });
}

@reflectiveTest
class DartfixTest extends AbstractAnalysisServerIntegrationTest {
  void setupTarget() {
    writeFile(sourcePath('test.dart'), '''
class A {}
class B extends A {}
class C with B {}
    ''');
    standardAnalysisSetup();
  }

  Future<void> test_dartfix_exclude() async {
    setupTarget();
    var result = await sendEditDartfix([(sourceDirectory.path)],
        excludedFixes: ['convert_class_to_mixin']);
    expect(result.hasErrors, isFalse);
    expect(result.suggestions.length, 0);
    expect(result.edits.length, 0);
  }

  Future<void> test_dartfix_include() async {
    setupTarget();
    var result = await sendEditDartfix([(sourceDirectory.path)],
        includedFixes: ['convert_class_to_mixin']);
    expect(result.hasErrors, isFalse);
    expect(result.suggestions.length, greaterThanOrEqualTo(1));
    expect(result.edits.length, greaterThanOrEqualTo(1));
  }

  Future<void> test_dartfix_include_other() async {
    setupTarget();
    var result = await sendEditDartfix([(sourceDirectory.path)],
        includedFixes: ['prefer_int_literals']);
    expect(result.hasErrors, isFalse);
    expect(result.suggestions.length, 0);
    expect(result.edits.length, 0);
  }
}
