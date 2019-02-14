// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(EncapsulateFieldTest);
  });
}

@reflectiveTest
class EncapsulateFieldTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.ENCAPSULATE_FIELD;

  test_alreadyPrivate() async {
    await resolveTestUnit('''
class A {
  int _test = 42;
}
main(A a) {
  print(a._test);
}
''');
    await assertNoAssistAt('_test =');
  }

  test_documentation() async {
    await resolveTestUnit('''
class A {
  /// AAA
  /// BBB
  int test;
}
''');
    await assertHasAssistAt('test;', '''
class A {
  /// AAA
  /// BBB
  int _test;

  /// AAA
  /// BBB
  int get test => _test;

  /// AAA
  /// BBB
  set test(int test) {
    _test = test;
  }
}
''');
  }

  test_final() async {
    await resolveTestUnit('''
class A {
  final int test = 42;
}
''');
    await assertNoAssistAt('test =');
  }

  test_hasType() async {
    await resolveTestUnit('''
class A {
  int test = 42;
  A(this.test);
}
main(A a) {
  print(a.test);
}
''');
    await assertHasAssistAt('test = 42', '''
class A {
  int _test = 42;

  int get test => _test;

  set test(int test) {
    _test = test;
  }
  A(this._test);
}
main(A a) {
  print(a.test);
}
''');
  }

  test_multipleFields() async {
    await resolveTestUnit('''
class A {
  int aaa, bbb, ccc;
}
main(A a) {
  print(a.bbb);
}
''');
    await assertNoAssistAt('bbb, ');
  }

  test_notOnName() async {
    await resolveTestUnit('''
class A {
  int test = 1 + 2 + 3;
}
''');
    await assertNoAssistAt('+ 2');
  }

  test_noType() async {
    await resolveTestUnit('''
class A {
  var test = 42;
}
main(A a) {
  print(a.test);
}
''');
    await assertHasAssistAt('test = 42', '''
class A {
  var _test = 42;

  get test => _test;

  set test(test) {
    _test = test;
  }
}
main(A a) {
  print(a.test);
}
''');
  }

  test_parseError() async {
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
class A {
  int; // marker
}
main(A a) {
  print(a.test);
}
''');
    await assertNoAssistAt('; // marker');
  }

  test_static() async {
    await resolveTestUnit('''
class A {
  static int test = 42;
}
''');
    await assertNoAssistAt('test =');
  }
}
