// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToBoolExpressionBulkTest);
    defineReflectiveTests(ConvertToBoolExpressionTest);
  });
}

@reflectiveTest
class ConvertToBoolExpressionBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.no_literal_bool_comparisons;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void f(bool value) {
  if (value != false || value == false) print(value);
}
''');
    await assertHasFix('''
void f(bool value) {
  if (value || !value) print(value);
}
''');
  }
}

@reflectiveTest
class ConvertToBoolExpressionTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_BOOL_EXPRESSION;

  @override
  String get lintCode => LintNames.no_literal_bool_comparisons;

  Future<void> test_andAndFalse() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value && false) print(value);
}
''');
    var lint = await lintCodeByName(lintCode);
    await assertHasFix(r'''
void f(bool value) {
  if (false) print(value);
}
''', errorFilter: (error) => error.diagnosticCode == lint);
  }

  Future<void> test_andAndTrue() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value && true) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (value) print(value);
}
''');
  }

  Future<void> test_andFalse() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value & false) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (false) print(value);
}
''');
  }

  Future<void> test_andTrue() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value & true) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (value) print(value);
}
''');
  }

  Future<void> test_conditional_bothFalse() async {
    await resolveTestCode(r'''
void f(bool value1) {
  print(value1 ? false : false);
}
''');
    await assertHasFix(r'''
void f(bool value1) {
  print(false);
}
''');
  }

  Future<void> test_conditional_bothLiteral1() async {
    await resolveTestCode(r'''
void f(bool value1) {
  print(value1 ? true : false);
}
''');
    await assertHasFix(r'''
void f(bool value1) {
  print(value1);
}
''');
  }

  Future<void> test_conditional_bothLiteral2() async {
    await resolveTestCode(r'''
void f(bool value1) {
  print(value1 ? false : true);
}
''');
    await assertHasFix(r'''
void f(bool value1) {
  print(!value1);
}
''');
  }

  Future<void> test_conditional_bothTrue() async {
    await resolveTestCode(r'''
void f(bool value1) {
  print(value1 ? true : true);
}
''');
    await assertHasFix(r'''
void f(bool value1) {
  print(true);
}
''');
  }

  Future<void> test_conditional_elseFalse() async {
    await resolveTestCode(r'''
void f(bool value1, bool value2) {
  print(value1 ? value2 : false);
}
''');
    await assertHasFix(r'''
void f(bool value1, bool value2) {
  print(value1 && value2);
}
''');
  }

  Future<void> test_conditional_elseTrue() async {
    await resolveTestCode(r'''
void f(bool value1, bool value2) {
  print(value1 ? value2 : true);
}
''');
    await assertHasFix(r'''
void f(bool value1, bool value2) {
  print(!value1 || value2);
}
''');
  }

  Future<void> test_conditional_expressionCondition_else() async {
    await resolveTestCode(r'''
void f(int? value1, bool value2) {
  print(value1 == null ? false : value2);
}
''');
    await assertHasFix(r'''
void f(int? value1, bool value2) {
  print(!(value1 == null) && value2);
}
''');
  }

  Future<void> test_conditional_expressionCondition_then() async {
    await resolveTestCode(r'''
void f(int? value1, bool value2) {
  print(value1 == null || value1 == 0 ? value2 : false);
}
''');
    await assertHasFix(r'''
void f(int? value1, bool value2) {
  print((value1 == null || value1 == 0) && value2);
}
''');
  }

  Future<void> test_conditional_expressionElse() async {
    await resolveTestCode(r'''
void f(bool value1, bool? value2) {
  print(value1 ? false : value2 ?? false);
}
''');
    await assertHasFix(r'''
void f(bool value1, bool? value2) {
  print(!value1 && (value2 ?? false));
}
''');
  }

  Future<void> test_conditional_expressionThen() async {
    await resolveTestCode(r'''
void f(bool value1, bool? value2) {
  print(value1 ? value2 ?? false : false);
}
''');
    await assertHasFix(r'''
void f(bool value1, bool? value2) {
  print(value1 && (value2 ?? false));
}
''');
  }

  Future<void> test_conditional_thenFalse() async {
    await resolveTestCode(r'''
void f(bool value1, bool value2) {
  print(value1 ? false : value2);
}
''');
    await assertHasFix(r'''
void f(bool value1, bool value2) {
  print(!value1 && value2);
}
''');
  }

  Future<void> test_conditional_thenTrue() async {
    await resolveTestCode(r'''
void f(bool value1, bool value2) {
  print(value1 ? true : value2);
}
''');
    await assertHasFix(r'''
void f(bool value1, bool value2) {
  print(value1 || value2);
}
''');
  }

  Future<void> test_ifFalse() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value == false) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (!value) print(value);
}
''');
  }

  /// https://github.com/dart-lang/sdk/issues/52368
  Future<void> test_ifFalse_asExpression() async {
    await resolveTestCode(r'''
void f(Object value) {
  if (value as bool == false) print(value);
}
''');
    await assertHasFix(r'''
void f(Object value) {
  if (!(value as bool)) print(value);
}
''');
  }

  Future<void> test_ifFalse_reversed() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (false == value) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (!value) print(value);
}
''');
  }

  Future<void> test_ifNotFalse() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value != false) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (value) print(value);
}
''');
  }

  Future<void> test_ifNotFalse_reversed() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (false != value) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (value) print(value);
}
''');
  }

  Future<void> test_ifNotTrue() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value != true) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (!value) print(value);
}
''');
  }

  Future<void> test_ifNotTrue_reversed() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (true != value) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (!value) print(value);
}
''');
  }

  Future<void> test_ifTrue() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value == true) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (value) print(value);
}
''');
  }

  Future<void> test_ifTrue_invocation() async {
    await resolveTestCode(r'''
void f(bool Function() fn) {
  if (fn() == true) print('something');
}
''');
    await assertHasFix(r'''
void f(bool Function() fn) {
  if (fn()) print('something');
}
''');
  }

  Future<void> test_ifTrue_prefixed() async {
    await resolveTestCode(r'''
void f(List list) {
  if (list.isNotEmpty == true) print(list);
}
''');
    await assertHasFix(r'''
void f(List list) {
  if (list.isNotEmpty) print(list);
}
''');
  }

  Future<void> test_ifTrue_propertyAccess() async {
    await resolveTestCode(r'''
extension E on List {
  void m() {
    if (this.isNotEmpty == true) print(this);
  }
}
''');
    await assertHasFix(r'''
extension E on List {
  void m() {
    if (this.isNotEmpty) print(this);
  }
}
''');
  }

  Future<void> test_ifTrue_reversed() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (true == value) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (value) print(value);
}
''');
  }

  Future<void> test_orFalse() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value | false) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (value) print(value);
}
''');
  }

  Future<void> test_orOrFalse() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value || false) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (value) print(value);
}
''');
  }

  Future<void> test_orOrTrue() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value || true) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (true) print(value);
}
''');
  }

  Future<void> test_orTrue() async {
    await resolveTestCode(r'''
void f(bool value) {
  if (value | true) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (true) print(value);
}
''');
  }

  Future<void> test_xorFalse() async {
    allowTestCodeShorthand = false; // Test uses ^

    await resolveTestCode(r'''
void f(bool value) {
  if (value ^ false) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (value) print(value);
}
''');
  }

  Future<void> test_xorTrue() async {
    allowTestCodeShorthand = false; // Test uses ^

    await resolveTestCode(r'''
void f(bool value) {
  if (value ^ true) print(value);
}
''');
    await assertHasFix(r'''
void f(bool value) {
  if (!value) print(value);
}
''');
  }
}
