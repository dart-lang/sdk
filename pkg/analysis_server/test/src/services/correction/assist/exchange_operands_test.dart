// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExchangeOperandsTest);
  });
}

@reflectiveTest
class ExchangeOperandsTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.exchangeOperands;

  Future<void> test_compare() async {
    const initialOperators = ['<', '<=', '>', '>='];
    const resultOperators = ['>', '>=', '<', '<='];
    for (var i = 0; i <= 0; i++) {
      var initialOperator = initialOperators[i];
      var resultOperator = resultOperators[i];
      await resolveTestCode('''
bool f(int a, int b) {
  return a ^$initialOperator b;
}
''');
      await assertHasAssist('''
bool f(int a, int b) {
  return b $resultOperator a;
}
''');
    }
  }

  Future<void> test_extended_mixOperator_1() async {
    await resolveTestCode('''
void f() {
  1 ^* 2 * 3 + 4;
}
''');
    await assertHasAssist('''
void f() {
  2 * 3 * 1 + 4;
}
''');
  }

  Future<void> test_extended_mixOperator_2() async {
    await resolveTestCode('''
void f() {
  1 ^+ 2 - 3 + 4;
}
''');
    await assertHasAssist('''
void f() {
  2 + 1 - 3 + 4;
}
''');
  }

  Future<void> test_extended_sameOperator_afterFirst() async {
    await resolveTestCode('''
void f() {
  1 ^+ 2 + 3;
}
''');
    await assertHasAssist('''
void f() {
  2 + 3 + 1;
}
''');
  }

  Future<void> test_extended_sameOperator_afterSecond() async {
    await resolveTestCode('''
void f() {
  1 + 2 ^+ 3;
}
''');
    await assertHasAssist('''
void f() {
  3 + 1 + 2;
}
''');
  }

  Future<void> test_extraLength() async {
    await resolveTestCode('''
void f() {
  111 /*[0*/+ 2/*0]*/22;
}
''');
    await assertNoAssist();
  }

  Future<void> test_onOperand() async {
    await resolveTestCode('''
void f() {
  1/*[0*/11 +/*0]*/ 222;
}
''');
    await assertNoAssist();
  }

  Future<void> test_selectionWithBinary() async {
    await resolveTestCode('''
void f() {
  /*[0*/1 + 2 + 3/*0]*/;
}
''');
    await assertNoAssist();
  }

  Future<void> test_simple_afterOperator() async {
    await resolveTestCode('''
void f() {
  1 +^ 2;
}
''');
    await assertHasAssist('''
void f() {
  2 + 1;
}
''');
  }

  Future<void> test_simple_beforeOperator() async {
    await resolveTestCode('''
void f() {
  1 ^+ 2;
}
''');
    await assertHasAssist('''
void f() {
  2 + 1;
}
''');
  }

  Future<void> test_simple_fullSelection() async {
    await resolveTestCode('''
void f() {
  /*[0*/1 + 2/*0]*/;
}
''');
    await assertHasAssist('''
void f() {
  2 + 1;
}
''');
  }

  Future<void> test_simple_withLength() async {
    await resolveTestCode('''
void f() {
  1 /*[0*/+ /*0]*/2;
}
''');
    await assertHasAssist('''
void f() {
  2 + 1;
}
''');
  }
}
