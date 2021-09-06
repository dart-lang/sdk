// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToNormalParameterTest);
  });
}

@reflectiveTest
class ConvertToNormalParameterTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_NORMAL_PARAMETER;

  Future<void> test_dynamic() async {
    await resolveTestCode('''
class A {
  var test;
  A(this.test) {
  }
}
''');
    await assertHasAssistAt('test)', '''
class A {
  var test;
  A(test) : test = test {
  }
}
''');
  }

  Future<void> test_firstInitializer() async {
    await resolveTestCode('''
class A {
  int test;
  A(this.test) {
  }
}
''');
    await assertHasAssistAt('test)', '''
class A {
  int test;
  A(int test) : test = test {
  }
}
''');
  }

  Future<void> test_secondInitializer() async {
    await resolveTestCode('''
class A {
  double aaa;
  int bbb;
  A(this.bbb) : aaa = 1.0;
}
''');
    await assertHasAssistAt('bbb)', '''
class A {
  double aaa;
  int bbb;
  A(int bbb) : aaa = 1.0, bbb = bbb;
}
''');
  }
}
