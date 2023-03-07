// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SurroundWithIfTest);
  });
}

@reflectiveTest
class SurroundWithIfTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.SURROUND_WITH_IF;

  Future<void> test_encloseForWithPattern() async {
    await resolveTestCode('''
void f() {
// start
  for (var (a, b) = (0, 1); a <= 13; (a, b) = (b, a + b)) print(a);
// end
}
''');
    await assertHasAssist('''
void f() {
  if (condition) {
    for (var (a, b) = (0, 1); a <= 13; (a, b) = (b, a + b)) print(a);
  }
}
''');
    assertLinkedGroup(0, ['condition']);
    assertExitPosition(after: '  }');
  }

  Future<void> test_twoStatements() async {
    await resolveTestCode('''
void f() {
// start
  print(0);
  print(1);
// end
}
''');
    await assertHasAssist('''
void f() {
  if (condition) {
    print(0);
    print(1);
  }
}
''');
    assertLinkedGroup(0, ['condition']);
    assertExitPosition(after: '  }');
  }
}
