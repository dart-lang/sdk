// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SplitAndConditionTest);
  });
}

@reflectiveTest
class SplitAndConditionTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.SPLIT_AND_CONDITION;

  Future<void> test_hasElse() async {
    await resolveTestCode('''
main() {
  if (1 == 1 && 2 == 2) {
    print(1);
  } else {
    print(2);
  }
}
''');
    await assertNoAssistAt('&& 2');
  }

  Future<void> test_innerAndExpression() async {
    await resolveTestCode('''
main() {
  if (1 == 1 && 2 == 2 && 3 == 3) {
    print(0);
  }
}
''');
    await assertHasAssistAt('&& 2 == 2', '''
main() {
  if (1 == 1) {
    if (2 == 2 && 3 == 3) {
      print(0);
    }
  }
}
''');
  }

  Future<void> test_notAnd() async {
    await resolveTestCode('''
main() {
  if (1 == 1 || 2 == 2) {
    print(0);
  }
}
''');
    await assertNoAssistAt('|| 2');
  }

  Future<void> test_notOnOperator() async {
    await resolveTestCode('''
main() {
  if (1 == 1 && 2 == 2) {
    print(0);
  }
  print(3 == 3 && 4 == 4);
}
''');
    await assertNoAssistAt('main() {');
  }

  Future<void> test_notPartOfIf() async {
    await resolveTestCode('''
main() {
  print(1 == 1 && 2 == 2);
}
''');
    await assertNoAssistAt('&& 2');
  }

  Future<void> test_notTopLevelAnd() async {
    await resolveTestCode('''
main() {
  if (true || (1 == 1 && 2 == 2)) {
    print(0);
  }
  if (true && (3 == 3 && 4 == 4)) {
    print(0);
  }
}
''');
    await assertNoAssistAt('&& 2');
    await assertNoAssistAt('&& 4');
  }

  Future<void> test_selectionTooLarge() async {
    await resolveTestCode('''
main() {
  if (1 == 1
// start
&& 2 
// end
== 2
) {
    print(0);
  }
  print(3 == 3 && 4 == 4);
}
''');
    await assertNoAssist();
  }

  Future<void> test_thenBlock() async {
    await resolveTestCode('''
main() {
  if (true && false) {
    print(0);
    if (3 == 3) {
      print(1);
    }
  }
}
''');
    await assertHasAssistAt('&& false', '''
main() {
  if (true) {
    if (false) {
      print(0);
      if (3 == 3) {
        print(1);
      }
    }
  }
}
''');
  }

  Future<void> test_thenStatement() async {
    await resolveTestCode('''
main() {
  if (true && false)
    print(0);
}
''');
    await assertHasAssistAt('&& false', '''
main() {
  if (true)
    if (false)
      print(0);
}
''');
  }
}
