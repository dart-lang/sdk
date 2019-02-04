// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

main() {
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

  test_insideFunctionTypedFormalParameter() async {
    await resolveTestUnit('''
bad(void foo(/*LINT*/dynamic x)) {
  return null;
}
''');
    await assertHasFix('''
bad(void foo(/*LINT*/x)) {
  return null;
}
''');
  }

  test_namedParameter() async {
    await resolveTestUnit('''
bad({/*LINT*/dynamic defaultValue}) {
  return null;
}
''');
    await assertHasFix('''
bad({/*LINT*/defaultValue}) {
  return null;
}
''');
  }

  test_normalParameter() async {
    await resolveTestUnit('''
bad(/*LINT*/dynamic defaultValue) {
  return null;
}
''');
    await assertHasFix('''
bad(/*LINT*/defaultValue) {
  return null;
}
''');
  }

  test_optionalParameter() async {
    await resolveTestUnit('''
bad([/*LINT*/dynamic defaultValue]) {
  return null;
}
''');
    await assertHasFix('''
bad([/*LINT*/defaultValue]) {
  return null;
}
''');
  }
}

@reflectiveTest
class AvoidReturnTypesOnSettersTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.avoid_return_types_on_setters;

  test_void() async {
    await resolveTestUnit('''
/*LINT*/void set speed2(int ms) {}
''');
    await assertHasFix('''
/*LINT*/set speed2(int ms) {}
''');
  }
}

@reflectiveTest
class AvoidTypesOnClosureParametersTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.avoid_types_on_closure_parameters;

  test_namedParameter() async {
    await resolveTestUnit('''
var x = ({/*LINT*/Future<int> defaultValue}) {
  return null;
};
''');
    await assertHasFix('''
var x = ({/*LINT*/defaultValue}) {
  return null;
};
''');
  }

  test_normalParameter() async {
    await resolveTestUnit('''
var x = (/*LINT*/Future<int> defaultValue) {
  return null;
};
''');
    await assertHasFix('''
var x = (/*LINT*/defaultValue) {
  return null;
};
''');
  }

  test_optionalParameter() async {
    await resolveTestUnit('''
var x = ([/*LINT*/Future<int> defaultValue]) {
  return null;
};
''');
    await assertHasFix('''
var x = ([/*LINT*/defaultValue]) {
  return null;
};
''');
  }
}

@reflectiveTest
class TypeInitFormalsTest extends RemoveTypeAnnotationTest {
  @override
  String get lintCode => LintNames.type_init_formals;

  test_void() async {
    await resolveTestUnit('''
class C {
  int f;
  C(/*LINT*/int this.f);
}
''');
    await assertHasFix('''
class C {
  int f;
  C(/*LINT*/this.f);
}
''');
  }
}

@reflectiveTest
abstract class RemoveTypeAnnotationTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.REMOVE_TYPE_ANNOTATION;
}
