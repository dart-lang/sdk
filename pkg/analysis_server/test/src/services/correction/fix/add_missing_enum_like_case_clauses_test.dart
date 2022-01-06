// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddMissingEnumLikeCaseClausesTest);
  });
}

@reflectiveTest
class AddMissingEnumLikeCaseClausesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_MISSING_ENUM_CASE_CLAUSES;

  @override
  String get lintCode => LintNames.exhaustive_cases;

  bool Function(AnalysisError) get _filter {
    var hasError = false;
    return (error) {
      var errorCode = error.errorCode;
      if (!hasError && errorCode is LintCode && errorCode.name == lintCode) {
        hasError = true;
        return true;
      }
      return false;
    };
  }

  Future<void> assertHasFixWithFilter(String expected) async {
    await assertHasFix(expected, errorFilter: _filter);
  }

  Future<void> test_empty() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFixWithFilter('''
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_empty_singleLine() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {}
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFixWithFilter('''
void f(E e) {
  switch (e) {
    case E.a:
      // TODO: Handle this case.
      break;
    case E.b:
      // TODO: Handle this case.
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
  }

  Future<void> test_notEmpty() async {
    await resolveTestCode('''
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
    await assertHasFix('''
void f(E e) {
  switch (e) {
    case E.a:
      break;
    case E.b:
      break;
    case E.c:
      // TODO: Handle this case.
      break;
  }
}
class E {
  static const E a = E._(0);
  static const E b = E._(1);
  static const E c = E._(2);
  final int x;
  const E._(this.x);
}
''');
  }
}
