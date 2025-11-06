// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
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
  void v1() {}
  void v2() {}
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
  void v1() {}
  void v2() {}
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
      lints: [LintNames.prefer_function_declarations_over_variables],
    );
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
  void v() {
    void v() {}
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
  FixKind get kind => DartFixKind.convertToFunctionDeclaration;

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
  void v() {}
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
  void v2(x, y) {}
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
  int v() => 3;
  v();
}
''');
  }

  Future<void> test_functionTypedParameter() async {
    await resolveTestCode('''
void f() {
  int Function(int Function(String)?) v1 = (p) {
    return p?.call('') ?? 0;
  };
  v1((s) => 0);
}
''');
    await assertHasFix('''
void f() {
  int v1(int Function(String)? p) {
    return p?.call('') ?? 0;
  }
  v1((s) => 0);
}
''');
  }

  Future<void> test_futureIntBody() async {
    await resolveTestCode('''
void f() {
  final v1 = () async {
    return 0;
  };
  v1();
}
''');
    await assertHasFix('''
void f() {
  Future<int> v1() async {
    return 0;
  }
  v1();
}
''');
  }

  Future<void> test_futureVoid() async {
    await resolveTestCode('''
void f() {
  final v1 = () async {
  };
  v1();
}
''');
    await assertHasFix('''
void f() {
  Future<void> v1() async {
  }
  v1();
}
''');
  }

  Future<void> test_innerFunctions() async {
    await resolveTestCode('''
void f() {
  final v1 = () {
    () {
      return 0;
    };
    () => 0;
  };
  v1();
}
''');
    await assertHasFix('''
void f() {
  void v1() {
    () {
      return 0;
    };
    () => 0;
  }
  v1();
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
  void g() {}
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
  String v() => throw '';
  v();
}
''');
  }

  Future<void> test_typedefTyped() async {
    await resolveTestCode('''
typedef T = int Function(int);

void f() {
  T v1 = (p) {
    return p;
  };
  v1(0);
}
''');
    await assertHasFix('''
typedef T = int Function(int);

void f() {
  int v1(int p) {
    return p;
  }
  v1(0);
}
''');
  }

  Future<void> test_typeParameter() async {
    await resolveTestCode('''
void f() {
  final v1 = <T>(T p) {
  };
  v1(0);
}
''');
    await assertHasFix('''
void f() {
  void v1<T>(T p) {
  }
  v1(0);
}
''');
  }

  Future<void> test_variableTyped() async {
    await resolveTestCode('''
void f() {
  int Function(int) v1 = (p) {
    return p;
  };
  v1(0);
}
''');
    await assertHasFix('''
void f() {
  int v1(int p) {
    return p;
  }
  v1(0);
}
''');
  }
}
