// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddReturnTypeTest);
  });
}

@reflectiveTest
class AddReturnTypeTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.ADD_RETURN_TYPE;

  Future<void> test_localFunction_block() async {
    await resolveTestCode('''
class A {
  void m() {
    /*caret*/f() {
      return '';
    }
  }
}
''');
    await assertHasAssist('''
class A {
  void m() {
    String f() {
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
    /*caret*/f() => '';
  }
}
''');
    await assertHasAssist('''
class A {
  void m() {
    String f() => '';
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

  Future<void> test_method_block_returnDynamic() async {
    await resolveTestCode('''
class A {
  /*caret*/m(p) {
    return p;
  }
}
''');
    await assertHasAssist('''
class A {
  dynamic m(p) {
    return p;
  }
}
''');
  }

  Future<void> test_method_block_returnNoValue() async {
    await resolveTestCode('''
class A {
  /*caret*/m() {
    return;
  }
}
''');
    await assertHasAssist('''
class A {
  void m() {
    return;
  }
}
''');
  }

  Future<void> test_method_block_singleReturn() async {
    await resolveTestCode('''
class A {
  /*caret*/m() {
    return '';
  }
}
''');
    await assertHasAssist('''
class A {
  String m() {
    return '';
  }
}
''');
  }

  Future<void> test_method_expression() async {
    await resolveTestCode('''
class A {
  /*caret*/m() => '';
}
''');
    await assertHasAssist('''
class A {
  String m() => '';
}
''');
  }

  Future<void> test_method_getter() async {
    await resolveTestCode('''
class A {
  get /*caret*/foo => 0;
}
''');
    await assertHasAssist('''
class A {
  int get foo => 0;
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
    await assertHasAssist('''
class A {
  void set foo(int a) {
    if (a == 0) return;
  }
}
''');
  }

  Future<void> test_method_setter_lint_avoidReturnTypesOnSetters() async {
    createAnalysisOptionsFile(lints: [
      LintNames.avoid_return_types_on_setters,
    ]);
    await resolveTestCode('''
class A {
  set /*caret*/foo(int a) {
    if (a == 0) return;
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_topLevelFunction_block() async {
    await resolveTestCode('''
/*caret*/f() {
  return '';
}
''');
    await assertHasAssist('''
String f() {
  return '';
}
''');
  }

  Future<void> test_topLevelFunction_expression() async {
    await resolveTestCode('''
/*caret*/f() => '';
''');
    await assertHasAssist('''
String f() => '';
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
get /*caret*/foo => 0;
''');
    await assertHasAssist('''
int get foo => 0;
''');
  }

  Future<void> test_topLevelFunction_setter() async {
    await resolveTestCode('''
set /*caret*/foo(int a) {
  if (a == 0) return;
}
''');
    await assertHasAssist('''
void set foo(int a) {
  if (a == 0) return;
}
''');
  }

  Future<void>
      test_topLevelFunction_setter_lint_avoidReturnTypesOnSetters() async {
    createAnalysisOptionsFile(lints: [
      LintNames.avoid_return_types_on_setters,
    ]);
    await resolveTestCode('''
set /*caret*/foo(int a) {
  if (a == 0) return;
}
''');
    await assertNoAssist();
  }
}
