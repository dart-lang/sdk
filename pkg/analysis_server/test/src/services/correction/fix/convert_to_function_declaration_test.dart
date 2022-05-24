// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/expect.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToFunctionDeclarationBulkTest);
    defineReflectiveTests(ConvertToFunctionDeclarationInFileTest);
    defineReflectiveTests(ConvertToFunctionDeclarationTest);
  });
}

@reflectiveTest
class ConvertToFunctionDeclarationBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_function_declarations_over_variables;

  Future<void> test_bulk() async {
    await resolveTestCode('''
void f() {
  var v1 = () {};
  var v2 = () {};
  v1();
  v2();
}
''');
    await assertHasFix('''
void f() {
  v1() {}
  v2() {}
  v1();
  v2();
}
''');
  }

  Future<void> test_declaration_list() async {
    await resolveTestCode('''
void f() {
  var v1 = () {}, v2 = () {};
  v1();
  v2();
}
''');
    await assertHasFix('''
void f() {
  v1() {}
  v2() {}
  v1();
  v2();
}
''');
  }
}

@reflectiveTest
class ConvertToFunctionDeclarationInFileTest extends FixInFileProcessorTest {
  Future<void> test_file() async {
    createAnalysisOptionsFile(
        lints: [LintNames.prefer_function_declarations_over_variables]);
    await resolveTestCode('''
void f() {
  var v = () {
    var v = () {};
    v();
  };
  v();
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, '''
void f() {
  v() {
    v() {}
    v();
  }
  v();
}
''');
  }
}

@reflectiveTest
class ConvertToFunctionDeclarationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_TO_FUNCTION_DECLARATION;

  @override
  String get lintCode => LintNames.prefer_function_declarations_over_variables;

  Future<void> test_block_function_body() async {
    await resolveTestCode('''
void f() {
  var v = () {};
  v();
}
''');
    await assertHasFix('''
void f() {
  v() {}
  v();
}
''');
  }

  Future<void> test_declaration_different() async {
    await resolveTestCode('''
void f() {
  final v1 = 1, v2 = (x, y) {}, v3 = '';
  v2(v1, v3);
}
''');
    await assertHasFix('''
void f() {
  final v1 = 1;
  v2(x, y) {}
  final v3 = '';
  v2(v1, v3);
}
''');
  }

  Future<void> test_expression_function_body() async {
    await resolveTestCode('''
void f() {
  var v = () => 3;
  v();
}
''');
    await assertHasFix('''
void f() {
  v() => 3;
  v();
}
''');
  }

  Future<void> test_no_initializer() async {
    await resolveTestCode('''
typedef F = void Function();

void f() {
  final F g = () {}, h;
  g();
  h = () {};
  h();
}
''');
    await assertHasFix('''
typedef F = void Function();

void f() {
  g() {}
  final F h;
  g();
  h = () {};
  h();
}
''');
  }

  Future<void> test_type() async {
    await resolveTestCode('''
void f() {
  final String Function() v = () => throw '';
  v();
}
''');
    await assertHasFix('''
void f() {
  v() => throw '';
  v();
}
''');
  }
}
