// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(JoinIfWithOuterTest);
  });
}

@reflectiveTest
class JoinIfWithOuterTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.JOIN_IF_WITH_OUTER;

  Future<void> test_conditionAndOr() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    if (2 == 2 || 3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt('if (2 ==', '''
main() {
  if (1 == 1 && (2 == 2 || 3 == 3)) {
    print(0);
  }
}
''');
  }

  Future<void> test_conditionInvocation() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    if (isCheck()) {
      print(0);
    }
  }
}
bool isCheck() => false;
''');
    await assertHasAssistAt('if (isCheck', '''
main() {
  if (1 == 1 && isCheck()) {
    print(0);
  }
}
bool isCheck() => false;
''');
  }

  Future<void> test_conditionOrAnd() async {
    await resolveTestCode('''
main() {
  if (1 == 1 || 2 == 2) {
    if (3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt('if (3 == 3', '''
main() {
  if ((1 == 1 || 2 == 2) && 3 == 3) {
    print(0);
  }
}
''');
  }

  Future<void> test_onCondition() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt('if (2 == 2', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_outerNotIf() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    print(0);
  }
}
''');
    await assertNoAssistAt('if (1 == 1');
  }

  Future<void> test_outerWithElse() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  } else {
    print(1);
  }
}
''');
    await assertNoAssistAt('if (2 == 2');
  }

  Future<void> test_simpleConditions_block_block() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt('if (2 == 2', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_simpleConditions_block_single() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    if (2 == 2)
      print(0);
  }
}
''');
    await assertHasAssistAt('if (2 == 2', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_simpleConditions_single_blockMulti() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(1);
      print(2);
      print(3);
    }
  }
}
''');
    await assertHasAssistAt('if (2 == 2', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(1);
    print(2);
    print(3);
  }
}
''');
  }

  Future<void> test_simpleConditions_single_blockOne() async {
    await resolveTestCode('''
main() {
  if (1 == 1)
    if (2 == 2) {
      print(0);
    }
}
''');
    await assertHasAssistAt('if (2 == 2', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  Future<void> test_statementAfterInner() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(2);
    }
    print(1);
  }
}
''');
    await assertNoAssistAt('if (2 == 2');
  }

  Future<void> test_statementBeforeInner() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    print(1);
    if (2 == 2) {
      print(2);
    }
  }
}
''');
    await assertNoAssistAt('if (2 == 2');
  }

  Future<void> test_targetNotIf() async {
    await resolveTestCode('''
main() {
  print(0);
}
''');
    await assertNoAssistAt('print');
  }

  Future<void> test_targetWithElse() async {
    await resolveTestCode('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    } else {
      print(1);
    }
  }
}
''');
    await assertNoAssistAt('if (2 == 2');
  }
}
