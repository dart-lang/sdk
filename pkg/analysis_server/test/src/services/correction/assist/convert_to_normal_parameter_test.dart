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
  AssistKind get kind => DartAssistKind.convertToNormalParameter;

  Future<void> test_dynamic() async {
    await resolveTestCode('''
class A {
  var test;
  A(this.t^est) {
  }
}
''');
    await assertHasAssist('''
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
  A(this.te^st) {
  }
}
''');
    await assertHasAssist('''
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
  A(this.bb^b) : aaa = 1.0;
}
''');
    await assertHasAssist('''
class A {
  double aaa;
  int bbb;
  A(int bbb) : aaa = 1.0, bbb = bbb;
}
''');
  }
}
