// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'bulk_fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveMethodDeclarationTest);
  });
}

@reflectiveTest
class RemoveMethodDeclarationTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.unnecessary_overrides;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {
  int foo;
  int bar() => 0;
}

class B extends A {
  @override
  int get foo => super.foo;
  @override
  int bar() => super.bar();
}
''');
    await assertHasFix('''
class A {
  int foo;
  int bar() => 0;
}

class B extends A {
}
''');
  }
}
