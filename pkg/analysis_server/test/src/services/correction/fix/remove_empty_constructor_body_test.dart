// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveEmptyConstructorBodyBulkTest);
    defineReflectiveTests(RemoveEmptyConstructorBodyTest);
  });
}

@reflectiveTest
class RemoveEmptyConstructorBodyBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.empty_constructor_bodies;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  C() {}
}

class D {
  D() {}
}
''');
    await assertHasFix('''
class C {
  C();
}

class D {
  D();
}
''');
  }
}

@reflectiveTest
class RemoveEmptyConstructorBodyTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.removeEmptyConstructorBody;

  @override
  String get lintCode => LintNames.empty_constructor_bodies;

  Future<void> test_empty() async {
    await resolveTestCode('''
class C {
  C() {}
}
''');
    await assertHasFix('''
class C {
  C();
}
''');
  }

  Future<void> test_incompleteComment() async {
    await resolveTestCode(r'''
class A {
  A() {/*
''');
    await assertNoFix(filter: _isInterestingError);
  }

  static bool _isInterestingError(Diagnostic e) {
    return e.diagnosticCode.name == LintNames.empty_constructor_bodies;
  }
}
