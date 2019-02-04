// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoExpressionBodyTest);
  });
}

@reflectiveTest
class ConvertIntoExpressionBodyTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_EXPRESSION_BODY;

  test_already() async {
    await resolveTestUnit('''
fff() => 42;
''');
    await assertNoAssistAt('fff()');
  }

  test_async() async {
    await resolveTestUnit('''
class A {
  mmm() async {
    return 42;
  }
}
''');
    await assertHasAssistAt('mmm', '''
class A {
  mmm() async => 42;
}
''');
  }

  test_closure() async {
    await resolveTestUnit('''
setup(x) {}
main() {
  setup(() {
    return 42;
  });
}
''');
    await assertHasAssistAt('return', '''
setup(x) {}
main() {
  setup(() => 42);
}
''');
  }

  test_closure_voidExpression() async {
    await resolveTestUnit('''
setup(x) {}
main() {
  setup((_) {
    print('test');
  });
}
''');
    await assertHasAssistAt('(_) {', '''
setup(x) {}
main() {
  setup((_) => print('test'));
}
''');
  }

  test_constructor() async {
    await resolveTestUnit('''
class A {
  factory A() {
    return null;
  }
}
''');
    await assertHasAssistAt('A()', '''
class A {
  factory A() => null;
}
''');
  }

  test_function_onBlock() async {
    await resolveTestUnit('''
fff() {
  return 42;
}
''');
    await assertHasAssistAt('{', '''
fff() => 42;
''');
  }

  test_function_onName() async {
    await resolveTestUnit('''
fff() {
  return 42;
}
''');
    await assertHasAssistAt('ff()', '''
fff() => 42;
''');
  }

  test_inExpression() async {
    await resolveTestUnit('''
main() {
  return 42;
}
''');
    await assertNoAssistAt('42;');
  }

  test_method_onBlock() async {
    await resolveTestUnit('''
class A {
  m() { // marker
    return 42;
  }
}
''');
    await assertHasAssistAt('{ // marker', '''
class A {
  m() => 42;
}
''');
  }

  test_moreThanOneStatement() async {
    await resolveTestUnit('''
fff() {
  var v = 42;
  return v;
}
''');
    await assertNoAssistAt('fff()');
  }

  test_noEnclosingFunction() async {
    await resolveTestUnit('''
var V = 42;
''');
    await assertNoAssistAt('V = ');
  }

  test_noReturn() async {
    await resolveTestUnit('''
fff() {
  var v = 42;
}
''');
    await assertNoAssistAt('fff()');
  }

  test_noReturnValue() async {
    await resolveTestUnit('''
fff() {
  return;
}
''');
    await assertNoAssistAt('fff()');
  }

  test_topFunction_onReturnStatement() async {
    await resolveTestUnit('''
fff() {
  return 42;
}
''');
    await assertHasAssistAt('return', '''
fff() => 42;
''');
  }
}
