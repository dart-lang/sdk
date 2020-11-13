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
    defineReflectiveTests(AvoidAnnotatingWithDynamicTest);
    defineReflectiveTests(AvoidReturnTypesOnSettersTest);
    defineReflectiveTests(AvoidTypesOnClosureParametersTest);
    defineReflectiveTests(TypeInitFormalsTest);
  });
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
class AvoidTypesOnClosureParametersTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.avoid_types_on_closure_parameters;

  Future<void> test_namedParameter() async {
    await resolveTestCode('''
var x = ({Future<int> defaultValue}) => null;
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
var x = ([Future<int> defaultValue]) => null;
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
class TypeInitFormalsTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.type_init_formals;

  Future<void> test_void() async {
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
}
