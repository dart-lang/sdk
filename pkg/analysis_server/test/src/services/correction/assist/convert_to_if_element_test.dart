// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIfElementTest);
  });
}

@reflectiveTest
class ConvertToIfElementTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_IF_ELEMENT;

  Future<void> test_conditional_list() async {
    await resolveTestCode('''
f(bool b) {
  return ['a', b /*caret*/? 'c' : 'd', 'e'];
}
''');
    await assertHasAssist('''
f(bool b) {
  return ['a', if (b) 'c' else 'd', 'e'];
}
''');
  }

  Future<void> test_conditional_list_caret_at_start_of_expression() async {
    await resolveTestCode('''
f(bool b) {
  return ['a', /*caret*/b ? 'c' : 'd', 'e'];
}
''');
    await assertHasAssist('''
f(bool b) {
  return ['a', if (b) 'c' else 'd', 'e'];
}
''');
  }

  Future<void> test_conditional_list_noAssistWithLint() async {
    createAnalysisOptionsFile(
        lints: [LintNames.prefer_if_elements_to_conditional_expressions]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
f(bool b) {
  return ['a', b /*caret*/? 'c' : 'd', 'e'];
}
''');
    await assertNoAssist();
  }

  Future<void> test_conditional_list_withParentheses() async {
    await resolveTestCode('''
f(bool b) {
  return ['a', (b /*caret*/? 'c' : 'd'), 'e'];
}
''');
    await assertHasAssist('''
f(bool b) {
  return ['a', if (b) 'c' else 'd', 'e'];
}
''');
  }

  Future<void> test_conditional_map() async {
    await resolveTestCode('''
f(bool b) {
  return {'a' : 1, b /*caret*/? 'c' : 'd' : 2, 'e' : 3};
}
''');
    await assertNoAssist();
  }

  Future<void> test_conditional_notConditional() async {
    await resolveTestCode('''
f(bool b) {
  return {'/*caret*/a', b ? 'c' : 'd', 'e'};
}
''');
    await assertNoAssist();
  }

  Future<void> test_conditional_notInLiteral() async {
    await resolveTestCode('''
f(bool b) {
  return b /*caret*/? 'c' : 'd';
}
''');
    await assertNoAssist();
  }

  Future<void> test_conditional_set() async {
    await resolveTestCode('''
f(bool b) {
  return {'a', b /*caret*/? 'c' : 'd', 'e'};
}
''');
    await assertHasAssist('''
f(bool b) {
  return {'a', if (b) 'c' else 'd', 'e'};
}
''');
  }

  Future<void> test_conditional_set_withParentheses() async {
    await resolveTestCode('''
f(bool b) {
  return {'a', ((b /*caret*/? 'c' : 'd')), 'e'};
}
''');
    await assertHasAssist('''
f(bool b) {
  return {'a', if (b) 'c' else 'd', 'e'};
}
''');
  }
}
