// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToFieldParameterTest);
  });
}

@reflectiveTest
class ConvertToFieldParameterTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_FIELD_PARAMETER;

  Future<void> test_additionalUse() async {
    await resolveTestCode('''
class A {
  int aaa2;
  int bbb2;
  A(int aaa) : aaa2 = aaa, bbb2 = aaa;
}
''');
    await assertNoAssistAt('aaa)');
  }

  Future<void> test_firstInitializer() async {
    await resolveTestCode('''
class A {
  int aaa2;
  int bbb2;
  A(int aaa, int bbb) : aaa2 = aaa, bbb2 = bbb;
}
''');
    await assertHasAssistAt('aaa, ', '''
class A {
  int aaa2;
  int bbb2;
  A(this.aaa2, int bbb) : bbb2 = bbb;
}
''');
  }

  Future<void> test_notPureAssignment() async {
    await resolveTestCode('''
class A {
  int aaa2;
  A(int aaa) : aaa2 = aaa * 2;
}
''');
    await assertNoAssistAt('aaa)');
  }

  Future<void> test_onParameterName_inInitializer() async {
    await resolveTestCode('''
class A {
  int test2;
  A(int test) : test2 = test {
  }
}
''');
    await assertHasAssistAt('test {', '''
class A {
  int test2;
  A(this.test2) {
  }
}
''');
  }

  Future<void> test_onParameterName_inParameters() async {
    await resolveTestCode('''
class A {
  int test;
  A(int test) : test = test {
  }
}
''');
    await assertHasAssistAt('test)', '''
class A {
  int test;
  A(this.test) {
  }
}
''');
  }

  Future<void> test_secondInitializer() async {
    await resolveTestCode('''
class A {
  int aaa2;
  int bbb2;
  A(int aaa, int bbb) : aaa2 = aaa, bbb2 = bbb;
}
''');
    await assertHasAssistAt('bbb)', '''
class A {
  int aaa2;
  int bbb2;
  A(int aaa, this.bbb2) : aaa2 = aaa;
}
''');
  }
}
