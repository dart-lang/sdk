// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveReturnTypeTest);
  });
}

@reflectiveTest
class RemoveReturnTypeTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.REMOVE_RETURN_TYPE;

  Future<void> test_localFunction_block() async {
    await resolveTestCode('''
class A {
  void m() {
    String /*caret*/f() {
      return '';
    }
  }
}
''');
    await assertHasAssist('''
class A {
  void m() {
    f() {
      return '';
    }
  }
}
''');
  }

  Future<void> test_localFunction_expression() async {
    await resolveTestCode('''
class A {
  void m() {
    String /*caret*/f() => '';
  }
}
''');
    await assertHasAssist('''
class A {
  void m() {
    f() => '';
  }
}
''');
  }

  Future<void> test_method_block_noReturn() async {
    await resolveTestCode('''
class A {
  /*caret*/m() {
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_method_block_noExplicitReturn() async {
    await resolveTestCode('''
class A {
  /*caret*/m() => '';
}
''');
    await assertNoAssist();
  }

  Future<void> test_method_block_returnDynamic() async {
    await resolveTestCode('''
class A {
  dynamic /*caret*/m(p) {
    return p;
  }
}
''');
    await assertHasAssist('''
class A {
  m(p) {
    return p;
  }
}
''');
  }

  Future<void> test_method_block_returnNoValue() async {
    await resolveTestCode('''
class A {
  void /*caret*/m() {
    return;
  }
}
''');
    await assertHasAssist('''
class A {
  m() {
    return;
  }
}
''');
  }

  Future<void> test_method_block_singleReturn() async {
    await resolveTestCode('''
class A {
  String /*caret*/m() {
    return '';
  }
}
''');
    await assertHasAssist('''
class A {
  m() {
    return '';
  }
}
''');
  }

  Future<void> test_method_expression() async {
    await resolveTestCode('''
class A {
  String /*caret*/m() => '';
}
''');
    await assertHasAssist('''
class A {
  m() => '';
}
''');
  }

  Future<void> test_method_getter() async {
    await resolveTestCode('''
class A {
  int get /*caret*/foo => 0;
}
''');
    await assertHasAssist('''
class A {
  get foo => 0;
}
''');
  }

  Future<void> test_method_setter() async {
    await resolveTestCode('''
class A {
  set /*caret*/foo(int a) {
    if (a == 0) return;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_method_setter_with_return() async {
    await resolveTestCode('''
class A {
  void set /*caret*/foo(int a) {
    if (a == 0) return;
  }
}
''');
    await assertHasAssist('''
class A {
  set foo(int a) {
    if (a == 0) return;
  }
}
''');
  }

  Future<void> test_topLevelFunction_block() async {
    await resolveTestCode('''
String /*caret*/f() {
  return '';
}
''');
    await assertHasAssist('''
f() {
  return '';
}
''');
  }

  Future<void> test_topLevelFunction_expression() async {
    await resolveTestCode('''
String /*caret*/f() => '';
''');
    await assertHasAssist('''
f() => '';
''');
  }

  Future<void> test_topLevelFunction_expression_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.always_declare_return_types]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
/*caret*/f() => '';
''');
    await assertNoAssist();
  }

  Future<void> test_topLevelFunction_getter() async {
    await resolveTestCode('''
int get /*caret*/foo => 0;
''');
    await assertHasAssist('''
get foo => 0;
''');
  }

  Future<void> test_topLevelFunction_setter() async {
    await resolveTestCode('''
set /*caret*/foo(int a) {
  if (a == 0) return;
}
''');
    await assertNoAssist();
  }

  Future<void> test_topLevelFunction_setter_with_return() async {
    await resolveTestCode('''
void set /*caret*/foo(int a) {
  if (a == 0) return;
}
''');
    await assertHasAssist('''
set /*caret*/foo(int a) {
  if (a == 0) return;
}
''');
  }
}
