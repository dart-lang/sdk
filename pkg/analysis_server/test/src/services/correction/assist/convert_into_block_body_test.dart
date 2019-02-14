// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoBlockBodyTest);
  });
}

@reflectiveTest
class ConvertIntoBlockBodyTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_BLOCK_BODY;

  test_async() async {
    await resolveTestUnit('''
class A {
  mmm() async => 123;
}
''');
    await assertHasAssistAt('mmm()', '''
class A {
  mmm() async {
    return 123;
  }
}
''');
  }

  test_closure() async {
    await resolveTestUnit('''
setup(x) {}
main() {
  setup(() => 42);
}
''');
    await assertHasAssistAt('() => 42', '''
setup(x) {}
main() {
  setup(() {
    return 42;
  });
}
''');
    assertExitPosition(after: '42;');
  }

  test_closure_voidExpression() async {
    await resolveTestUnit('''
setup(x) {}
main() {
  setup(() => print('done'));
}
''');
    await assertHasAssistAt('() => print', '''
setup(x) {}
main() {
  setup(() {
    print('done');
  });
}
''');
    assertExitPosition(after: "');");
  }

  test_constructor() async {
    await resolveTestUnit('''
class A {
  factory A() => null;
}
''');
    await assertHasAssistAt('A()', '''
class A {
  factory A() {
    return null;
  }
}
''');
  }

  test_inExpression() async {
    await resolveTestUnit('''
main() => 123;
''');
    await assertNoAssistAt('123;');
  }

  test_method() async {
    await resolveTestUnit('''
class A {
  mmm() => 123;
}
''');
    await assertHasAssistAt('mmm()', '''
class A {
  mmm() {
    return 123;
  }
}
''');
  }

  test_noEnclosingFunction() async {
    await resolveTestUnit('''
var v = 123;
''');
    await assertNoAssistAt('v =');
  }

  test_notExpressionBlock() async {
    await resolveTestUnit('''
fff() {
  return 123;
}
''');
    await assertNoAssistAt('fff() {');
  }

  test_onArrow() async {
    await resolveTestUnit('''
fff() => 123;
''');
    await assertHasAssistAt('=>', '''
fff() {
  return 123;
}
''');
  }

  test_onName() async {
    await resolveTestUnit('''
fff() => 123;
''');
    await assertHasAssistAt('fff()', '''
fff() {
  return 123;
}
''');
  }

  test_throw() async {
    await resolveTestUnit('''
class A {
  mmm() => throw 'error';
}
''');
    await assertHasAssistAt('mmm()', '''
class A {
  mmm() {
    throw 'error';
  }
}
''');
  }
}
