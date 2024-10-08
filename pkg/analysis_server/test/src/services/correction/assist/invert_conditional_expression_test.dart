// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvertConditionalExpressionTest);
  });
}

@reflectiveTest
class InvertConditionalExpressionTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.INVERT_CONDITIONAL_EXPRESSION;

  Future<void> test_thenStatement_elseStatement_on_colon() async {
    await resolveTestCode('''
void f() {
  true ? 0 /*caret*/: 1;
}
''');
    await assertHasAssist('''
void f() {
  false ? 1 : 0;
}
''');
  }

  Future<void> test_thenStatement_elseStatement_on_condition() async {
    await resolveTestCode('''
void f() {
  /*caret*/true ? 0 : 1;
}
''');
    await assertHasAssist('''
void f() {
  false ? 1 : 0;
}
''');
  }

  Future<void>
      test_thenStatement_elseStatement_on_conditionParentheses() async {
    await resolveTestCode('''
void f() {
  (t/*caret*/rue) ? 0 : 1;
}
''');
    await assertHasAssist('''
void f() {
  false ? 1 : 0;
}
''');
  }

  Future<void>
      test_thenStatement_elseStatement_on_conditionTestParentheses() async {
    await resolveTestCode('''
void f() {
  (1 ==/*caret*/ 1) ? 0 : 1;
}
''');
    await assertHasAssist('''
void f() {
  1 != 1 ? 1 : 0;
}
''');
  }

  Future<void> test_thenStatement_elseStatement_on_else() async {
    await resolveTestCode('''
void f() {
  true ? 0 : /*caret*/1;
}
''');
    await assertHasAssist('''
void f() {
  false ? 1 : 0;
}
''');
  }

  Future<void> test_thenStatement_elseStatement_on_question() async {
    await resolveTestCode('''
void f() {
  true /*caret*/? 0 : 1;
}
''');
    await assertHasAssist('''
void f() {
  false ? 1 : 0;
}
''');
  }

  Future<void> test_thenStatement_elseStatement_on_then() async {
    await resolveTestCode('''
void f() {
  true ? /*caret*/0 : 1;
}
''');
    await assertHasAssist('''
void f() {
  false ? 1 : 0;
}
''');
  }

  Future<void>
      test_thenStatement_elseStatement_on_thenAsyncParenthesizedFunction() async {
    await resolveTestCode('''
void f() async {
  (true) ? await (f/*caret*/n()) : 1;
}

Future<int> fn() async => 0;
''');
    await assertHasAssist('''
void f() async {
  false ? 1 : await (fn());
}

Future<int> fn() async => 0;
''');
  }

  Future<void> test_thenStatement_elseStatement_on_thenLambda() async {
    await resolveTestCode('''
void f() async {
  (true) ? () =>/*caret*/ 1 : 1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_thenStatement_elseStatement_on_thenLambdaBody() async {
    await resolveTestCode('''
void f() async {
  (true) ? () => /*caret*/1 : 1;
}
''');
    await assertNoAssist();
  }

  Future<void>
      test_thenStatement_elseStatement_on_thenLambdaParameters() async {
    await resolveTestCode('''
void f() async {
  (true) ? (/*caret*/) => 1 : 1;
}
''');
    await assertNoAssist();
  }

  Future<void>
      test_thenStatement_elseStatement_on_thenLambdaParenthesized() async {
    await resolveTestCode('''
void f() async {
  (true) ? (/*caret*/() => 1) : 1;
}
''');
    await assertNoAssist();
  }

  Future<void>
      test_thenStatement_elseStatement_on_thenParenthesesAsyncFunction() async {
    await resolveTestCode('''
void f() async {
  (true) ? (await f/*caret*/n()) : 1;
}

Future<void> fn() async {}
''');
    await assertHasAssist('''
void f() async {
  false ? 1 : (await fn());
}

Future<void> fn() async {}
''');
  }

  Future<void>
      test_thenStatement_elseStatement_on_thenParenthesesFunction() async {
    await resolveTestCode('''
void f() {
  (true) ? (f/*caret*/n()) : 1;
}

void fn() {}
''');
    await assertHasAssist('''
void f() {
  false ? 1 : (fn());
}

void fn() {}
''');
  }

  Future<void>
      test_thenStatement_elseStatement_on_thenParenthesesFunctionResultExpression() async {
    await resolveTestCode('''
void f() {
  (true) ? (f/*caret*/n() && false) : 1;
}

bool fn() => true;
''');
    await assertHasAssist('''
void f() {
  false ? 1 : (fn() && false);
}

bool fn() => true;
''');
  }

  Future<void>
      test_thenStatement_elseStatement_on_thenParenthesesTearoff() async {
    await resolveTestCode('''
void f() {
  (true) ? (f/*caret*/n) : 1;
}

void fn() {}
''');
    await assertHasAssist('''
void f() {
  false ? 1 : (fn);
}

void fn() {}
''');
  }

  Future<void> test_thenStatement_elseStatement_on_thenParenthesized() async {
    await resolveTestCode('''
void f() async {
  (true) ? /*caret*/(() => 1) : 1;
}
''');
    await assertHasAssist('''
void f() async {
  false ? 1 : (() => 1);
}
''');
  }

  Future<void> test_thenStatement_elseStatement_on_thenSumExp() async {
    await resolveTestCode('''
void f() async {
  (true) ? (1 + /*caret*/2) : 1;
}
''');
    await assertHasAssist('''
void f() async {
  false ? 1 : (1 + 2);
}
''');
  }
}
