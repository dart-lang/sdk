// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToListLiteralTest);
  });
}

@reflectiveTest
class ConvertToListLiteralTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_LIST_LITERAL;

  Future<void> test_default_declaredType() async {
    await resolveTestCode('''
List l = Li/*caret*/st();
''');
    await assertHasAssist('''
List l = [];
''');
  }

  Future<void> test_default_minimal() async {
    await resolveTestCode('''
var l = Li/*caret*/st();
''');
    await assertHasAssist('''
var l = [];
''');
  }

  Future<void> test_default_newKeyword() async {
    await resolveTestCode('''
var l = new Li/*caret*/st();
''');
    await assertHasAssist('''
var l = [];
''');
  }

  Future<void> test_default_tooManyArguments() async {
    await resolveTestCode('''
var l = Li/*caret*/st(5);
''');
    await assertNoAssist();
  }

  Future<void> test_default_typeArg() async {
    await resolveTestCode('''
var l = Li/*caret*/st<int>();
''');
    await assertHasAssist('''
var l = <int>[];
''');
  }
}
