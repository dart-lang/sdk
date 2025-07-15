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
  AssistKind get kind => DartAssistKind.convertToSwitchStatement;

  Future<void> test_chain_case2_blockEmpty() async {
    await resolveTestCode('''
void f(Object? x) {
  i^f (x case int()) {
  } else if (x case double()) {
    1;
  }
}
''');
    await assertHasAssist('''
void f(Object? x) {
  switch (x) {
    case int():
      break;
    case double():
      1;
  }
}
''');
  }

  Future<void> test_chain_case2_blockEmpty_last() async {
    await resolveTestCode('''
void f(Object? x) {
  i^f (x case int()) {
    0;
  } else if (x case double()) {
  }
}
''');
    await assertHasAssist('''
void f(Object? x) {
  switch (x) {
    case int():
      0;
    case double():
  }
}
''');
  }

  Future<void> test_chain_case2_differentIdentifier() async {
    await resolveTestCode('''
void f(Object? x, Object? y) {
  i^f (x case int()) {
    0;
  } else if (y case double()) {
    1;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_chain_case2_elseBlock() async {
    await resolveTestCode('''
void f(Object? x) {
  i^f (x case int()) {
    0;
  } else if (x case double()) {
    1;
  } else {
    2;
  }
}
''');
    await assertHasAssist('''
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
  i^f (x case int()) {
    0;
  } else if (x case double()) {
    1;
  }
}
''');
    await assertHasAssist('''
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
  i^f (x case int()) {
    0;
  } else if (x != null case true) {
    1;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_chain_case_expression() async {
    await resolveTestCode('''
void f(Object? x) {
  i^f (x case int()) {
    0;
  } else if (x is double) {
    1;
  }
}
''');
    await assertHasAssist('''
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
  i^f (x is int) {
    0;
  } else if (x is double) {
    1;
  }
}
''');
    await assertHasAssist('''
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
  i^f (x is int) {
    0;
  } else if (x is double) {
    1;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_single_case_thenBlock() async {
    await resolveTestCode('''
void f(Object? x) {
  i^f (x case int()) {
    0;
  }
}
''');
    await assertHasAssist('''
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
  i^f (x case int()) {
    0;
  } else {
    1;
  }
}
''');
    await assertHasAssist('''
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
  i^f (x case int()) {
    0;
  } else {}
}
''');
    await assertHasAssist('''
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
  i^f (x case int()) {
    0;
  } else
    1;
}
''');
    await assertHasAssist('''
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
  i^f (x case int())
    0;
}
''');
    await assertHasAssist('''
void f(Object? x) {
  switch (x) {
    case int():
      0;
  }
}
''');
  }

  Future<void> test_single_expression_greaterOrEqualThan() async {
    await resolveTestCode('''
void f(int x) {
  i^f (x >= 100) {
    0;
  }
}
''');
    await assertHasAssist('''
void f(int x) {
  switch (x) {
    case >= 100:
      0;
  }
}
''');
  }

  Future<void> test_single_expression_greaterThan() async {
    await resolveTestCode('''
void f(int x) {
  i^f (x > 100) {
    0;
  }
}
''');
    await assertHasAssist('''
void f(int x) {
  switch (x) {
    case > 100:
      0;
  }
}
''');
  }

  Future<void> test_single_expression_isType() async {
    await resolveTestCode('''
void f(Object? x) {
  i^f (x is List<int>) {
    0;
  }
}
''');
    await assertHasAssist('''
void f(Object? x) {
  switch (x) {
    case List<int>():
      0;
  }
}
''');
  }

  Future<void> test_single_expression_isType_functionType() async {
    await resolveTestCode('''
void f(Object? x) {
  i^f (x is void Function()) {
    0;
  }
}
''');
    await assertHasAssist('''
void f(Object? x) {
  switch (x) {
    case void Function() _:
      0;
  }
}
''');
  }

  Future<void> test_single_expression_isType_recordType() async {
    await resolveTestCode('''
void f(Object? x) {
  i^f (x is (int, String)) {
    0;
  }
}
''');
    await assertHasAssist('''
void f(Object? x) {
  switch (x) {
    case (int, String) _:
      0;
  }
}
''');
  }

  Future<void> test_single_expression_lessOrEqualThan() async {
    await resolveTestCode('''
void f(int x) {
  i^f (x <= 100) {
    0;
  }
}
''');
    await assertHasAssist('''
void f(int x) {
  switch (x) {
    case <= 100:
      0;
  }
}
''');
  }

  Future<void> test_single_expression_lessThan() async {
    await resolveTestCode('''
void f(int x) {
  i^f (x < 100) {
    0;
  }
}
''');
    await assertHasAssist('''
void f(int x) {
  switch (x) {
    case < 100:
      0;
  }
}
''');
  }

  Future<void> test_single_expression_lessThan_notLiteral() async {
    await resolveTestCode('''
void f(int x, int y) {
  i^f (x < y) {
    0;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_single_expression_notEqNull() async {
    await resolveTestCode('''
void f(Object? x) {
  i^f (x != null) {
    0;
  }
}
''');
    await assertHasAssist('''
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
  i^f (validate(x)) {
    0;
  }
}

bool validate(Object? x) => false;
''');
    await assertNoAssist();
  }
}

@reflectiveTest
class ConvertSwitchExpressionToSwitchStatementTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertToSwitchStatement;

  Future<void> test_assignment_toIdentifier() async {
    await resolveTestCode('''
void f(int x) {
  int v;
  v = swi^tch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssist('''
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
  v[0] = swi^tch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertNoAssist();
  }

  Future<void> test_noTrailingComma() async {
    await resolveTestCode('''
int f(int x) {
  return sw^itch (x) {
    0 => 0,
    _ => 1
  };
}
''');
    await assertHasAssist('''
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

  Future<void> test_operatorAssignment() async {
    await resolveTestCode('''
void f(int x) {
  int v = 0;
  v += s^witch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssist('''
void f(int x) {
  int v = 0;
  switch (x) {
    case 0:
      v += 0;
    default:
      v += 1;
  }
}
''');
  }

  Future<void> test_returnStatement() async {
    await resolveTestCode('''
int f(int x) {
  return swi^tch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssist('''
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
  int v = swi^tch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssist('''
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
  final v = swi^tch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssist('''
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
  var v = swi^tch (x) {
    0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssist('''
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
  int v = swi^tch (x) {
    _ when x > 0 => 0,
    _ => 1,
  };
}
''');
    await assertHasAssist('''
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
