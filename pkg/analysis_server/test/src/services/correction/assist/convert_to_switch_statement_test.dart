// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToSwitchStatementTest);
  });
}

@reflectiveTest
class ConvertToSwitchStatementTest extends AssistProcessorTest {
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
