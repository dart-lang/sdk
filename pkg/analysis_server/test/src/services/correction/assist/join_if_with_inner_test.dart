// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(JoinInWithInnerTest);
  });
}

@reflectiveTest
class JoinInWithInnerTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.JOIN_IF_WITH_INNER;

  test_conditionAndOr() async {
    await resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2 || 3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt('if (1 ==', '''
main() {
  if (1 == 1 && (2 == 2 || 3 == 3)) {
    print(0);
  }
}
''');
  }

  test_conditionInvocation() async {
    await resolveTestUnit('''
main() {
  if (isCheck()) {
    if (2 == 2) {
      print(0);
    }
  }
}
bool isCheck() => false;
''');
    await assertHasAssistAt('if (isCheck', '''
main() {
  if (isCheck() && 2 == 2) {
    print(0);
  }
}
bool isCheck() => false;
''');
  }

  test_conditionOrAnd() async {
    await resolveTestUnit('''
main() {
  if (1 == 1 || 2 == 2) {
    if (3 == 3) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt('if (1 ==', '''
main() {
  if ((1 == 1 || 2 == 2) && 3 == 3) {
    print(0);
  }
}
''');
  }

  test_innerNotIf() async {
    await resolveTestUnit('''
main() {
  if (1 == 1) {
    print(0);
  }
}
''');
    await assertNoAssistAt('if (1 ==');
  }

  test_innerWithElse() async {
    await resolveTestUnit('''
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
    await assertNoAssistAt('if (1 ==');
  }

  test_onCondition() async {
    await resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt('1 ==', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_simpleConditions_block_block() async {
    await resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(0);
    }
  }
}
''');
    await assertHasAssistAt('if (1 ==', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_simpleConditions_block_single() async {
    await resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2)
      print(0);
  }
}
''');
    await assertHasAssistAt('if (1 ==', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_simpleConditions_single_blockMulti() async {
    await resolveTestUnit('''
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
    await assertHasAssistAt('if (1 ==', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(1);
    print(2);
    print(3);
  }
}
''');
  }

  test_simpleConditions_single_blockOne() async {
    await resolveTestUnit('''
main() {
  if (1 == 1)
    if (2 == 2) {
      print(0);
    }
}
''');
    await assertHasAssistAt('if (1 ==', '''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
}
''');
  }

  test_statementAfterInner() async {
    await resolveTestUnit('''
main() {
  if (1 == 1) {
    if (2 == 2) {
      print(2);
    }
    print(1);
  }
}
''');
    await assertNoAssistAt('if (1 ==');
  }

  test_statementBeforeInner() async {
    await resolveTestUnit('''
main() {
  if (1 == 1) {
    print(1);
    if (2 == 2) {
      print(2);
    }
  }
}
''');
    await assertNoAssistAt('if (1 ==');
  }

  test_targetNotIf() async {
    await resolveTestUnit('''
main() {
  print(0);
}
''');
    await assertNoAssistAt('print');
  }

  test_targetWithElse() async {
    await resolveTestUnit('''
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
    await assertNoAssistAt('if (1 ==');
  }
}
