// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SplitVariableDeclarationTest);
  });
}

@reflectiveTest
class SplitVariableDeclarationTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.SPLIT_VARIABLE_DECLARATION;

  Future<void> test_const() async {
    await resolveTestCode('''
main() {
  const v = 1;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_final() async {
    await resolveTestCode('''
main() {
  final v = 1;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_notOneVariable() async {
    await resolveTestCode('''
main() {
  var v = 1, v2;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_onName() async {
    await resolveTestCode('''
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

  Future<void> test_onName_functionStatement_noType() async {
    await resolveTestCode('''
f() => 1;
main() {
  var v = f();
}
''');
    await assertHasAssistAt('v =', '''
f() => 1;
main() {
  var v;
  v = f();
}
''');
  }

  Future<void> test_onType() async {
    await resolveTestCode('''
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
  Future<void> test_onType_prefixedByComment() async {
    await resolveTestCode('''
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

  Future<void> test_onVar() async {
    await resolveTestCode('''
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
