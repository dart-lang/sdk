// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BulkFixesTest);
  });
}

@reflectiveTest
class BulkFixesTest extends AbstractAnalysisServerIntegrationTest {
  void setupTarget() {
    writeFile(sourcePath('test.dart'), '''
class A {
  void f() {}
}
class B extends A {
  void f() { }
}
''');
    standardAnalysisSetup();
  }

  @failingTest
  Future<void> test_bulk_fix_override() async {
    setupTarget();

    var result = await sendEditBulkFixes([sourceDirectory.path]);
    expect(result.edits.length, 1);
  }
}
