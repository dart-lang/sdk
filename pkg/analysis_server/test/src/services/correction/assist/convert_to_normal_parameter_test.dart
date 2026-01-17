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

  Future<void> test_privateNamedParameter_optionalNamed() async {
    await resolveTestCode('''
class A {
  int? _foo;
  A({this._f^oo});
}
''');
    await assertHasAssist('''
class A {
  int? _foo;
  A({int? foo}) : _foo = foo;
}
''');
  }

  Future<void> test_privateNamedParameter_requiredNamed() async {
    await resolveTestCode('''
class A {
  int _foo;
  A({required this._f^oo});
}
''');
    await assertHasAssist('''
class A {
  int _foo;
  A({required int foo}) : _foo = foo;
}
''');
  }

  Future<void> test_privateNamedParameter_withExistingInitializer() async {
    await resolveTestCode('''
class A {
  double aaa;
  int _bbb;
  A({required this._bb^b}) : aaa = 1.0;
}
''');
    await assertHasAssist('''
class A {
  double aaa;
  int _bbb;
  A({required int bbb}) : aaa = 1.0, _bbb = bbb;
}
''');
  }

  Future<void> test_privateNamedParameter_disabled() async {
    await resolveTestCode('''
// @dart=3.10
class A {
  int? _foo;
  A({this._f^oo});
}
''');
    await assertHasAssist('''
// @dart=3.10
class A {
  int? _foo;
  A({int? _foo}) : _foo = _foo;
}
''');
  }
}
