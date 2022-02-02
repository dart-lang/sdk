// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidAnnotatingWithDynamicBulkTest);
    defineReflectiveTests(AvoidAnnotatingWithDynamicTest);
    defineReflectiveTests(AvoidReturnTypesOnSettersBulkTest);
    defineReflectiveTests(AvoidReturnTypesOnSettersTest);
    defineReflectiveTests(AvoidTypesOnClosureParametersBulkTest);
    defineReflectiveTests(AvoidTypesOnClosureParametersTest);
    defineReflectiveTests(TypeInitFormalsBulkTest);
    defineReflectiveTests(TypeInitFormalsTest);
  });
}

@reflectiveTest
class AvoidAnnotatingWithDynamicBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_annotating_with_dynamic;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
f(void foo(dynamic x)) {
  return null;
}

f2({dynamic defaultValue}) {
  return null;
}
''');
    await assertHasFix('''
f(void foo(x)) {
  return null;
}

f2({defaultValue}) {
  return null;
}
''');
  }
}

@reflectiveTest
class AvoidAnnotatingWithDynamicTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.avoid_annotating_with_dynamic;

  Future<void> test_insideFunctionTypedFormalParameter() async {
    await resolveTestCode('''
bad(void foo(dynamic x)) {
  return null;
}
''');
    await assertHasFix('''
bad(void foo(x)) {
  return null;
}
''');
  }

  Future<void> test_namedParameter() async {
    await resolveTestCode('''
bad({dynamic defaultValue}) {
  return null;
}
''');
    await assertHasFix('''
bad({defaultValue}) {
  return null;
}
''');
  }

  Future<void> test_normalParameter() async {
    await resolveTestCode('''
bad(dynamic defaultValue) {
  return null;
}
''');
    await assertHasFix('''
bad(defaultValue) {
  return null;
}
''');
  }

  Future<void> test_optionalParameter() async {
    await resolveTestCode('''
bad([dynamic defaultValue]) {
  return null;
}
''');
    await assertHasFix('''
bad([defaultValue]) {
  return null;
}
''');
  }
}

@reflectiveTest
class AvoidReturnTypesOnSettersBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_return_types_on_setters;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
void set s(int s) {}
void set s2(int s2) {}
''');
    await assertHasFix('''
set s(int s) {}
set s2(int s2) {}
''');
  }
}

@reflectiveTest
class AvoidReturnTypesOnSettersTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.avoid_return_types_on_setters;

  Future<void> test_void() async {
    await resolveTestCode('''
void set speed2(int ms) {}
''');
    await assertHasFix('''
set speed2(int ms) {}
''');
  }
}

@reflectiveTest
class AvoidTypesOnClosureParametersBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.avoid_types_on_closure_parameters;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
var x = ({Future<int> defaultValue}) => null;
var y = (Future<int> defaultValue) => null;
''');
    await assertHasFix('''
var x = ({defaultValue}) => null;
var y = (defaultValue) => null;
''');
  }
}

@reflectiveTest
class AvoidTypesOnClosureParametersTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.avoid_types_on_closure_parameters;

  Future<void> test_namedParameter() async {
    await resolveTestCode('''
var x = ({Future<int>? defaultValue}) => null;
''');
    await assertHasFix('''
var x = ({defaultValue}) => null;
''');
  }

  Future<void> test_normalParameter() async {
    await resolveTestCode('''
var x = (Future<int> defaultValue) => null;
''');
    await assertHasFix('''
var x = (defaultValue) => null;
''');
  }

  Future<void> test_optionalParameter() async {
    await resolveTestCode('''
var x = ([Future<int>? defaultValue]) => null;
''');
    await assertHasFix('''
var x = ([defaultValue]) => null;
''');
  }
}

@reflectiveTest
abstract class RemoveTypeAnnotationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_TYPE_ANNOTATION;
}

@reflectiveTest
class TypeInitFormalsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.type_init_formals;

  Future<void> test_singleFile() async {
    await resolveTestCode('''
class C {
  int f;
  C(int this.f);
}

class Point {
  int x, y;
  Point(int this.x, int this.y);
}
''');
    await assertHasFix('''
class C {
  int f;
  C(this.f);
}

class Point {
  int x, y;
  Point(this.x, this.y);
}
''');
  }
}

@reflectiveTest
class TypeInitFormalsTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.type_init_formals;

  Future<void> test_formalFieldParameter() async {
    await resolveTestCode('''
class C {
  int f;
  C(int this.f);
}
''');
    await assertHasFix('''
class C {
  int f;
  C(this.f);
}
''');
  }

  @FailingTest(issue: 'https://github.com/dart-lang/linter/issues/3210')
  Future<void> test_superParameter() async {
    // If this issue gets closed as "won't fix," remove this test.
    await resolveTestCode('''
class C {
  C(int f);
}
class D extends C {
  D(int super.f);
}
''');
    await assertHasFix('''
class C {
  int f;
  C(super.f);
}
''');
  }
}
