// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/dart/error/lint_codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIfNullPreferBulkTest);
    defineReflectiveTests(ConvertToIfNullPreferTest);
    defineReflectiveTests(ConvertToIfNullUseBulkTest);
    defineReflectiveTests(ConvertToIfNullUseTest);
  });
}

@reflectiveTest
class ConvertToIfNullPreferBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_if_null_operators;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(String s) {
  print(s == null ? 'default' : s);
  print(s != null ? s : 'default');
}
''');
    await assertHasFix('''
void f(String s) {
  print(s ?? 'default');
  print(s ?? 'default');
}
''');
  }
}

@reflectiveTest
class ConvertToIfNullPreferTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertToIfNull;

  @override
  String get lintCode => LintNames.prefer_if_null_operators;

  Future<void> test_conditional_expression() async {
    await resolveTestCode('''
void f(bool multiline, int? maxLines) {
  var lines = maxLines != null
      ? maxLines
      : multiline ? 5 : 1;
  print(lines);
}
''');
    await assertHasFix('''
void f(bool multiline, int? maxLines) {
  var lines = maxLines ?? (multiline ? 5 : 1);
  print(lines);
}
''');
  }

  Future<void> test_equalEqual() async {
    await resolveTestCode('''
void f(String? s) {
  print(s == null ? 'default' : s);
}
''');
    await assertHasFix('''
void f(String? s) {
  print(s ?? 'default');
}
''');
  }

  Future<void> test_malformed() async {
    await resolveTestCode('''
void f(String s, bool b) {
  print(b ? s != null ? s : : null);
}
''');
    await assertNoFix(
      errorFilter: (error) {
        var code = error.diagnosticCode;
        return code is LintCode &&
            code.name == LintNames.prefer_if_null_operators;
      },
    );
  }

  Future<void> test_malformed_parentheses() async {
    // https://github.com/dart-lang/sdk/issues/43432
    await resolveTestCode('''
void f(String s, bool b) {
  print(b ? (s != null ? s : ) : null);
}
''');
    await assertNoFix(
      errorFilter: (error) {
        var code = error.diagnosticCode;
        return code is LintCode &&
            code.name == LintNames.prefer_if_null_operators;
      },
    );
  }

  Future<void> test_notEqual() async {
    await resolveTestCode('''
void f(String? s) {
  print(s != null ? s : 'default');
}
''');
    await assertHasFix('''
void f(String? s) {
  print(s ?? 'default');
}
''');
  }

  Future<void> test_nullLiteral() async {
    await resolveTestCode('''
void f(String? s) {
  print(s == null ? null : s);
}
''');
    await assertHasFix('''
void f(String? s) {
  print(s);
}
''');
  }
}

@reflectiveTest
class ConvertToIfNullUseBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.use_if_null_to_convert_nulls_to_bools;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(bool? value) {
  print(value == true);
  print(value != false);
}
''');
    await assertHasFix('''
void f(bool? value) {
  print(value ?? false);
  print(value ?? true);
}
''');
  }
}

@reflectiveTest
class ConvertToIfNullUseTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.convertToIfNull;

  @override
  String get lintCode => LintNames.use_if_null_to_convert_nulls_to_bools;

  Future<void> test_different_false() async {
    await resolveTestCode('''
void f(bool? value) {
  print(value != false);
}
''');
    await assertHasFix('''
void f(bool? value) {
  print(value ?? true);
}
''');
  }

  Future<void> test_equals_true() async {
    await resolveTestCode('''
void f(bool? value) {
  print(value == true);
}
''');
    await assertHasFix('''
void f(bool? value) {
  print(value ?? false);
}
''');
  }

  Future<void> test_parensAround() async {
    await resolveTestCode('''
void f(bool? value) {
  print(value != false && 1 == 2);
}
''');
    await assertHasFix('''
void f(bool? value) {
  print((value ?? true) && 1 == 2);
}
''');
  }
}
