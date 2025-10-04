// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddReturnType_AlwaysDeclareReturnTypesTest);
    defineReflectiveTests(AddReturnType_StrictTopLevelInferenceTest);
    defineReflectiveTests(AddReturnTypeBulkTest);
  });
}

@reflectiveTest
class AddReturnType_AlwaysDeclareReturnTypesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.addReturnType;

  @override
  String get lintCode => LintNames.always_declare_return_types;

  Future<void> test_localFunction_block() async {
    await resolveTestCode('''
class A {
  void m() {
    f() {
      return '';
    }
    f();
  }
}
''');
    await assertHasFix('''
class A {
  void m() {
    String f() {
      return '';
    }
    f();
  }
}
''');
  }

  Future<void> test_localFunction_expression() async {
    await resolveTestCode('''
class A {
  void m() {
    f() => '';
    f();
  }
}
''');
    await assertHasFix('''
class A {
  void m() {
    String f() => '';
    f();
  }
}
''');
  }

  Future<void> test_method_block_noReturn() async {
    await resolveTestCode('''
class A {
  m() {}
}
''');
    await assertHasFix('''
class A {
  void m() {}
}
''');
  }

  Future<void> test_method_block_returnDynamic() async {
    await resolveTestCode('''
class A {
  m(p) {
    return p;
  }
}
''');
    await assertHasFix('''
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
  m() {
    return;
  }
}
''');
    await assertHasFix('''
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
  m() {
    return '';
  }
}
''');
    await assertHasFix('''
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
  m() => '';
}
''');
    await assertHasFix('''
class A {
  String m() => '';
}
''');
  }

  Future<void> test_method_getter() async {
    await resolveTestCode('''
class A {
  get foo => 0;
}
''');
    await assertHasFix('''
class A {
  int get foo => 0;
}
''');
  }

  Future<void> test_operator() async {
    await resolveTestCode('''
class MyObject extends Object {
  operator ==(Object other) => false;
}
''');
    await assertHasFix('''
class MyObject extends Object {
  bool operator ==(Object other) => false;
}
''');
  }

  Future<void> test_privateType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  _B b => _B();
}
class _B {}
''');

    await resolveTestCode('''
import 'package:test/a.dart';

f(A a) => a.b();
''');
    await assertHasFix('''
import 'package:test/a.dart';

Object f(A a) => a.b();
''');
  }

  Future<void> test_topLevelFunction_async_hasReturns() async {
    await resolveTestCode('''
f() async {
  if (1 == 2) {
    return 0;
  } else {
    return 1.5;
  }
}
''');
    await assertHasFix('''
Future<num> f() async {
  if (1 == 2) {
    return 0;
  } else {
    return 1.5;
  }
}
''');
  }

  Future<void> test_topLevelFunction_async_noReturns() async {
    await resolveTestCode('''
f() async {}
''');
    await assertHasFix('''
Future<void> f() async {}
''');
  }

  Future<void> test_topLevelFunction_asyncStar_noYield() async {
    await resolveTestCode('''
f() async* {}
''');
    await assertHasFix('''
Stream<void> f() async* {}
''');
  }

  Future<void> test_topLevelFunction_asyncStar_withYield() async {
    await resolveTestCode('''
f() async* {
  yield 0;
  yield 1.5;
}
''');
    await assertHasFix('''
Stream<num> f() async* {
  yield 0;
  yield 1.5;
}
''');
  }

  Future<void> test_topLevelFunction_block() async {
    await resolveTestCode('''
f() {
  return '';
}
''');
    await assertHasFix('''
String f() {
  return '';
}
''');
  }

  Future<void> test_topLevelFunction_expression() async {
    await resolveTestCode('''
f() => '';
''');
    await assertHasFix('''
String f() => '';
''');
  }

  Future<void> test_topLevelFunction_getter() async {
    await resolveTestCode('''
get foo => 0;
''');
    await assertHasFix('''
int get foo => 0;
''');
  }

  Future<void> test_topLevelFunction_syncStar_noYield() async {
    await resolveTestCode('''
f() sync* {}
''');
    await assertHasFix('''
Iterable<void> f() sync* {}
''');
  }

  Future<void> test_topLevelFunction_syncStar_withYield() async {
    await resolveTestCode('''
f() sync* {
  yield 0;
  yield 1.5;
}
''');
    await assertHasFix('''
Iterable<num> f() sync* {
  yield 0;
  yield 1.5;
}
''');
  }
}

@reflectiveTest
class AddReturnType_StrictTopLevelInferenceTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.addReturnType;

  @override
  String get lintCode => LintNames.strict_top_level_inference;

  Future<void> test_instanceMethod_typeVariable() async {
    await resolveTestCode('''
class C<T> {
  f(T p) {
    return p;
  }
}
''');
    await assertHasFix('''
class C<T> {
  T f(T p) {
    return p;
  }
}
''');
  }

  Future<void> test_topLevelFunction() async {
    await resolveTestCode('''
f() {
  return '';
}
''');
    await assertHasFix('''
String f() {
  return '';
}
''');
  }

  Future<void> test_topLevelFunction_typeVariable() async {
    await resolveTestCode('''
f<T>(T p) {
  return [p];
}
''');
    await assertHasFix('''
List<T> f<T>(T p) {
  return [p];
}
''');
  }
}

@reflectiveTest
class AddReturnTypeBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.always_declare_return_types;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class A {
  get foo => 0;
  m(p) {
    return p;
  }
}
''');
    await assertHasFix('''
class A {
  int get foo => 0;
  dynamic m(p) {
    return p;
  }
}
''');
  }
}
