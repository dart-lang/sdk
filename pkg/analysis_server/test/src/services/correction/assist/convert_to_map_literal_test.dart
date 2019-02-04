// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToMapLiteralTest);
  });
}

@reflectiveTest
class ConvertToMapLiteralTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_MAP_LITERAL;

  test_default_declaredType() async {
    await resolveTestUnit('''
Map m = Ma/*caret*/p();
''');
    await assertHasAssist('''
Map m = {};
''');
  }

  test_default_minimal() async {
    await resolveTestUnit('''
var m = Ma/*caret*/p();
''');
    await assertHasAssist('''
var m = {};
''');
  }

  test_default_newKeyword() async {
    await resolveTestUnit('''
var m = new Ma/*caret*/p();
''');
    await assertHasAssist('''
var m = {};
''');
  }

  test_default_typeArg() async {
    await resolveTestUnit('''
var m = Ma/*caret*/p<String, int>();
''');
    await assertHasAssist('''
var m = <String, int>{};
''');
  }
}
