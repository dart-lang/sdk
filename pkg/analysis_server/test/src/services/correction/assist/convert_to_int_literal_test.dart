// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIntLiteralTest);
  });
}

@reflectiveTest
class ConvertToIntLiteralTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_INT_LITERAL;

  test_decimal() async {
    await resolveTestUnit('''
const double myDouble = /*caret*/42.0;
''');
    await assertHasAssist('''
const double myDouble = /*caret*/42;
''');
  }

  test_notDouble() async {
    await resolveTestUnit('''
const double myDouble = /*caret*/42;
''');
    await assertNoAssist();
  }

  test_scientific() async {
    await resolveTestUnit('''
const double myDouble = /*caret*/4.2e1;
''');
    await assertHasAssist('''
const double myDouble = /*caret*/42;
''');
  }

  test_tooBig() async {
    await resolveTestUnit('''
const double myDouble = /*caret*/4.2e99999;
''');
    await assertNoAssist();
  }
}
