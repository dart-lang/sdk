// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIfStatementToSwitchStatementTest);
    defineReflectiveTests(ConvertSwitchExpressionToSwitchStatementTest);
  });
}

@reflectiveTest
class ConvertIfStatementToSwitchStatementTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_SWITCH_STATEMENT;

  Future<void> test_chain_case2_differentIdentifier() async {
    await resolveTestCode('''
void f(Object? x, Object? y) {
  if (x case int()) {
    0;
  } else if (y case double()) {
    1;
  }
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_chain_case2_elseBlock() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int()) {
    0;
  } else if (x case double()) {
    1;
  } else {
    2;
  }
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    case double():
      1;
    default:
      2;
  }
}
''');
  }

  Future<void> test_chain_case2_noElse() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int()) {
    0;
  } else if (x case double()) {
    1;
  }
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    case double():
      1;
  }
}
''');
  }

  Future<void> test_chain_case2_notIdentifier() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int()) {
    0;
  } else if (x != null case true) {
    1;
  }
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_chain_case_expression() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int()) {
    0;
  } else if (x is double) {
    1;
  }
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    case double():
      1;
  }
}
''');
  }

  Future<void> test_chain_expression2() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x is int) {
    0;
  } else if (x is double) {
    1;
  }
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    case double():
      1;
  }
}
''');
  }

  Future<void> test_chain_expression2_language219() async {
    await resolveTestCode('''
// @dart = 2.19
void f(Object? x) {
  if (x is int) {
    0;
  } else if (x is double) {
    1;
  }
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_single_case_thenBlock() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int()) {
    0;
  }
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case int():
      0;
  }
}
''');
  }

  Future<void> test_single_case_thenBlock_elseBlock() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int()) {
    0;
  } else {
    1;
  }
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    default:
      1;
  }
}
''');
  }

  Future<void> test_single_case_thenBlock_elseBlockEmpty() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int()) {
    0;
  } else {}
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    default:
  }
}
''');
  }

  Future<void> test_single_case_thenBlock_elseStatement() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int()) {
    0;
  } else
    1;
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    default:
      1;
  }
}
''');
  }

  Future<void> test_single_case_thenStatement() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x case int())
    0;
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case int():
      0;
  }
}
''');
  }

  Future<void> test_single_expression_isType() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x is List<int>) {
    0;
  }
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case List<int>():
      0;
  }
}
''');
  }

  Future<void> test_single_expression_notEqNull() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x != null) {
    0;
  }
}
''');
    await assertHasAssistAt('if', '''
void f(Object? x) {
  switch (x) {
    case _?:
      0;
  }
}
''');
  }

  Future<void> test_single_expression_notSupported() async {
    await resolveTestCode('''
void f(Object? x) {
  if (validate(x)) {
    0;
  }
}

bool validate(Object? x) => false;
''');
    await assertNoAssistAt('if');
  }
}

@reflectiveTest
class ConvertSwitchExpressionToSwitchStatementTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_SWITCH_STATEMENT;

  Future<void> test_assignment_toIdentifier() async {
    await resolveTestCode('''
void f(int x) {
  int v;
  v = switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssistAt('switch', '''
void f(int x) {
  int v;
  switch (x) {
    case 0:
      v = 0;
    default:
      v = 1;
  }
}
''');
  }

  Future<void> test_assignment_toIndex() async {
    await resolveTestCode('''
void f(int x) {
  final v = [0];
  v[0] = switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertNoAssistAt('switch');
  }

  Future<void> test_noTrailingComma() async {
    await resolveTestCode('''
int f(int x) {
  return switch (x) {
    0 => 0,
    _ => 1
  };
}
''');
    await assertHasAssistAt('switch', '''
int f(int x) {
  switch (x) {
    case 0:
      return 0;
    default:
      return 1;
  }
}
''');
  }

  Future<void> test_returnStatement() async {
    await resolveTestCode('''
int f(int x) {
  return switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssistAt('switch', '''
int f(int x) {
  switch (x) {
    case 0:
      return 0;
    default:
      return 1;
  }
}
''');
  }

  Future<void> test_variableDeclarationStatement_typed() async {
    await resolveTestCode('''
void f(int x) {
  int v = switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssistAt('switch', '''
void f(int x) {
  int v;
  switch (x) {
    case 0:
      v = 0;
    default:
      v = 1;
  }
}
''');
  }

  Future<void> test_variableDeclarationStatement_untyped_final() async {
    await resolveTestCode('''
void f(int x) {
  final v = switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssistAt('switch', '''
void f(int x) {
  final int v;
  switch (x) {
    case 0:
      v = 0;
    default:
      v = 1;
  }
}
''');
  }

  Future<void> test_variableDeclarationStatement_untyped_var() async {
    await resolveTestCode('''
void f(int x) {
  var v = switch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssistAt('switch', '''
void f(int x) {
  int v;
  switch (x) {
    case 0:
      v = 0;
    default:
      v = 1;
  }
}
''');
  }

  Future<void> test_wildcardPattern_when() async {
    await resolveTestCode('''
void f(int x) {
  int v = switch (x) {
    _ when x > 0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssistAt('switch', '''
void f(int x) {
  int v;
  switch (x) {
    case _ when x > 0:
      v = 0;
    default:
      v = 1;
  }
}
''');
  }
}
