// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SplitVariableDeclarationTest);
  });
}

@reflectiveTest
class SplitVariableDeclarationTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.SPLIT_VARIABLE_DECLARATION;

  test_const() async {
    await resolveTestUnit('''
main() {
  const v = 1;
}
''');
    await assertNoAssistAt('v = 1');
  }

  test_final() async {
    await resolveTestUnit('''
main() {
  final v = 1;
}
''');
    await assertNoAssistAt('v = 1');
  }

  test_notOneVariable() async {
    await resolveTestUnit('''
main() {
  var v = 1, v2;
}
''');
    await assertNoAssistAt('v = 1');
  }

  test_onName() async {
    await resolveTestUnit('''
main() {
  var v = 1;
}
''');
    await assertHasAssistAt('v =', '''
main() {
  int v;
  v = 1;
}
''');
  }

  test_onType() async {
    await resolveTestUnit('''
main() {
  int v = 1;
}
''');
    await assertHasAssistAt('int ', '''
main() {
  int v;
  v = 1;
}
''');
  }

  @failingTest
  test_onType_prefixedByComment() async {
    await resolveTestUnit('''
main() {
  /*comment*/int v = 1;
}
''');
    await assertHasAssistAt('int ', '''
main() {
  /*comment*/int v;
  v = 1;
}
''');
  }

  test_onVar() async {
    await resolveTestUnit('''
main() {
  var v = 1;
}
''');
    await assertHasAssistAt('var ', '''
main() {
  int v;
  v = 1;
}
''');
  }
}
