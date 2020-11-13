// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvertIfStatementTest);
  });
}

@reflectiveTest
class InvertIfStatementTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.INVERT_IF_STATEMENT;

  Future<void> test_blocks() async {
    await resolveTestCode('''
main() {
  if (true) {
    0;
  } else {
    1;
  }
}
''');
    await assertHasAssistAt('if (', '''
main() {
  if (false) {
    1;
  } else {
    0;
  }
}
''');
  }

  Future<void> test_statements() async {
    await resolveTestCode('''
main() {
  if (true)
    0;
  else
    1;
}
''');
    await assertHasAssistAt('if (', '''
main() {
  if (false)
    1;
  else
    0;
}
''');
  }
}
