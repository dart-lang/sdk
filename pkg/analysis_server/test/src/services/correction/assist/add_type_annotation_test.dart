// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analysis_server/src/services/linter/lint_names.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddTypeAnnotationTest);
  });
}

@reflectiveTest
class AddTypeAnnotationTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.ADD_TYPE_ANNOTATION;

  Future<void> test_classField_final() async {
    await resolveTestCode('''
class A {
  final f = 0;
}
''');
    await assertHasAssistAt('final ', '''
class A {
  final int f = 0;
}
''');
  }

  Future<void> test_classField_final_noAssistWithLint() async {
    createAnalysisOptionsFile(lints: [LintNames.always_specify_types]);
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
class A {
  /*caret*/final f = 0;
}
''');
    await assertNoAssist();
  }

  Future<void> test_classField_int() async {
    await resolveTestCode('''
class A {
  var f = 0;
}
''');
    await assertHasAssistAt('var ', '''
class A {
  int f = 0;
}
''');
  }

  Future<void> test_classField_recordType() async {
    await resolveTestCode('''
class A {
  var f = (2, b: 3);
}
''');
    await assertHasAssistAt('var ', '''
class A {
  (int, {int b}) f = (2, b: 3);
}
''');
  }

  Future<void> test_declaredIdentifier() async {
    await resolveTestCode('''
void f(List<String> items) {
  for (var item in items) {
  }
}
''');
    // on identifier
    await assertHasAssistAt('item in', '''
void f(List<String> items) {
  for (String item in items) {
  }
}
''');
    // on "for"
    await assertHasAssistAt('for (', '''
void f(List<String> items) {
  for (String item in items) {
  }
}
''');
  }

  Future<void> test_declaredIdentifier_addImport_dartUri() async {
    newFile('$testPackageLibPath/my_lib.dart', r'''
import 'dart:collection';
List<HashMap<String, int>> getMap() => null;
''');
    await resolveTestCode('''
import 'my_lib.dart';
void f() {
  for (var map in getMap()) {
  }
}
''');
    await assertHasAssistAt('map in', '''
import 'dart:collection';

import 'my_lib.dart';
void f() {
  for (HashMap<String, int> map in getMap()) {
  }
}
''');
  }

  Future<void> test_declaredIdentifier_final() async {
    await resolveTestCode('''
void f(List<String> items) {
  for (final item in items) {
  }
}
''');
    await assertHasAssistAt('item in', '''
void f(List<String> items) {
  for (final String item in items) {
  }
}
''');
  }

  Future<void> test_declaredIdentifier_generic() async {
    await resolveTestCode('''
class A<T> {
  void f(List<List<T>> items) {
    for (var item in items) {
    }
  }
}
''');
    await assertHasAssistAt('item in', '''
class A<T> {
  void f(List<List<T>> items) {
    for (List<T> item in items) {
    }
  }
}
''');
  }

  Future<void> test_declaredIdentifier_hasTypeAnnotation() async {
    await resolveTestCode('''
void f(List<String> items) {
  for (String item in items) {
  }
}
''');
    await assertNoAssistAt('item in');
  }

  Future<void> test_declaredIdentifier_inForEachBody() async {
    await resolveTestCode('''
void f(List<String> items) {
  for (var item in items) {
    42;
  }
}
''');
    await assertNoAssistAt('42;');
  }

  Future<void> test_declaredIdentifier_recordType() async {
    await resolveTestCode('''
void f(List<(int, {int a})> items) {
  for (final item in items) {
  }
}
''');
    await assertHasAssistAt('item in', '''
void f(List<(int, {int a})> items) {
  for (final (int, {int a}) item in items) {
  }
}
''');
  }

  Future<void> test_declaredIdentifier_unknownType() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  for (var item in unknownList) {
  }
}
''');
    await assertNoAssistAt('item in');
  }

  Future<void> test_local_addImport_dartUri() async {
    newFile('$testPackageLibPath/my_lib.dart', r'''
import 'dart:collection';
HashMap<String, int> getMap() => null;
''');
    await resolveTestCode('''
import 'my_lib.dart';
void f() {
  var v = getMap();
}
''');
    await assertHasAssistAt('v =', '''
import 'dart:collection';

import 'my_lib.dart';
void f() {
  HashMap<String, int> v = getMap();
}
''');
  }

  Future<void> test_local_addImport_notLibraryUnit() async {
    newFile('$testPackageLibPath/my_lib.dart', r'''
import 'dart:collection';
HashMap<String, int> getMap() => null;
''');

    var appCode = r'''
library my_app;
import 'my_lib.dart';
part 'test.dart';
''';
    addTestSource(r'''
part of my_app;
void f() {
  var /*caret*/v = getMap();
}
''');

    var appPath = convertPath('$testPackageLibPath/app.dart');
    newFile(appPath, appCode);
    await analyzeTestPackageFiles();
    await resolveTestFile();

    await assertHasAssist('''
part of my_app;
void f() {
  HashMap<String, int> v = getMap();
}
''', additionallyChangedFiles: {
      appPath: [
        appCode,
        '''
library my_app;
import 'dart:collection';

import 'my_lib.dart';
part 'test.dart';
'''
      ]
    });
  }

  Future<void> test_local_addImport_relUri() async {
    testFile = convertPath('/home/test/bin/test.dart');
    newFile('/home/test/bin/aa/bbb/lib_a.dart', r'''
class MyClass {}
''');
    newFile('/home/test/bin/ccc/lib_b.dart', r'''
import '../aa/bbb/lib_a.dart';
MyClass newMyClass() => null;
''');
    await resolveTestCode('''
import 'ccc/lib_b.dart';
void f() {
  var v = newMyClass();
}
''');
    await assertHasAssistAt('v =', '''
import 'aa/bbb/lib_a.dart';
import 'ccc/lib_b.dart';
void f() {
  MyClass v = newMyClass();
}
''');
  }

  Future<void> test_local_bottom() async {
    await resolveTestCode('''
void f() {
  var v = throw 42;
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_local_function() async {
    await resolveTestCode('''
void f() {
  var v = () => 1;
}
''');
    await assertHasAssistAt('v =', '''
void f() {
  int Function() v = () => 1;
}
''');
  }

  Future<void> test_local_function_optionalNamed() async {
    await resolveTestCode('''
void f({int arg = 0}) {}

var v = f;
''');
    await assertHasAssistAt('v =', '''
void f({int arg = 0}) {}

void Function({int arg}) v = f;
''');
  }

  Future<void> test_local_function_optionalPositional() async {
    await resolveTestCode('''
void f([int arg = 0]) {}

var v = f;
''');
    await assertHasAssistAt('v =', '''
void f([int arg = 0]) {}

void Function([int arg]) v = f;
''');
  }

  Future<void> test_local_generic_literal() async {
    await resolveTestCode('''
class A {
  void m(List<int> items) {
    var v = items;
  }
}
''');
    await assertHasAssistAt('v =', '''
class A {
  void m(List<int> items) {
    List<int> v = items;
  }
}
''');
  }

  Future<void> test_local_generic_local() async {
    await resolveTestCode('''
class A<T> {
  void m(List<T> items) {
    var v = items;
  }
}
''');
    await assertHasAssistAt('v =', '''
class A<T> {
  void m(List<T> items) {
    List<T> v = items;
  }
}
''');
  }

  Future<void> test_local_hasTypeAnnotation() async {
    await resolveTestCode('''
void f() {
  int v = 42;
}
''');
    await assertNoAssistAt(' = 42');
  }

  Future<void> test_local_int() async {
    await resolveTestCode('''
void f() {
  var v = 0;
}
''');
    await assertHasAssistAt('v =', '''
void f() {
  int v = 0;
}
''');
  }

  Future<void> test_local_List() async {
    await resolveTestCode('''
void f() {
  var v = <String>[];
}
''');
    await assertHasAssistAt('v =', '''
void f() {
  List<String> v = <String>[];
}
''');
  }

  Future<void> test_local_localType() async {
    await resolveTestCode('''
class C {}
C f() => C();
void g() {
  var x = f();
}
''');
    await assertHasAssistAt('x =', '''
class C {}
C f() => C();
void g() {
  C x = f();
}
''');
  }

  Future<void> test_local_multiple() async {
    await resolveTestCode('''
void f() {
  var a = 1, b = '';
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_local_multiple_same_type() async {
    await resolveTestCode('''
void f() {
  var a = '', b = '';
}
''');
    await assertHasAssistAt('var ', '''
void f() {
  String a = '', b = '';
}
''');
  }

  Future<void> test_local_noInitializer_noAssignments() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  var v;
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_local_noInitializer_oneAssignment_dynamic() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(p) {
  var v;
  v = p;
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_local_noInitializer_oneAssignment_functionType() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(int Function(int) p) {
  var v;
  v = p;
}
''');
    // TODO(brianwilkerson) Improve `DartChangeBuilder.writeType` so that
    //  unnecessary parameter names (`p1`) are not written.
    await assertHasAssistAt('var ', '''
void f(int Function(int) p) {
  int Function(int p1) v;
  v = p;
}
''');
  }

  Future<void> test_local_noInitializer_oneAssignment_insideClosure() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  var v;
  () {
    v = '';
  }();
}
''');
    await assertHasAssistAt('var ', '''
void f() {
  String v;
  () {
    v = '';
  }();
}
''');
  }

  Future<void> test_local_noInitializer_oneAssignment_interfaceType() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  var v;
  v = '';
}
''');
    await assertHasAssistAt('var ', '''
void f() {
  String v;
  v = '';
}
''');
  }

  Future<void> test_local_noInitializer_threeAssignments() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(int a, String b) {
  var v;
  v = a;
  v = null;
  v = b;
}
''');
    await assertHasAssistAt('var ', '''
void f(int a, String b) {
  Object? v;
  v = a;
  v = null;
  v = b;
}
''');
  }

  Future<void> test_local_noInitializer_twoAssignments_differentTypes() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  var v;
  v = 0;
  v = 3.1;
}
''');
    await assertHasAssistAt('var ', '''
void f() {
  num v;
  v = 0;
  v = 3.1;
}
''');
  }

  Future<void> test_local_noInitializer_twoAssignments_oneNull() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  var v;
  v = null;
  v = 0;
}
''');
    await assertHasAssistAt('var ', '''
void f() {
  int? v;
  v = null;
  v = 0;
}
''');
  }

  Future<void> test_local_noInitializer_twoAssignments_oneNullable() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f(int a, int? b) {
  var v;
  v = a;
  v = b;
}
''');
    await assertHasAssistAt('var ', '''
void f(int a, int? b) {
  int? v;
  v = a;
  v = b;
}
''');
  }

  Future<void> test_local_noInitializer_twoAssignments_sameTypes() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  var v;
  v = 'a';
  v = 'b';
}
''');
    await assertHasAssistAt('var ', '''
void f() {
  String v;
  v = 'a';
  v = 'b';
}
''');
  }

  Future<void> test_local_null() async {
    await resolveTestCode('''
void f() {
  var v = null;
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_local_onInitializer() async {
    await resolveTestCode('''
void f() {
  var abc = 0;
}
''');
    await assertNoAssistAt('0;');
  }

  Future<void> test_local_onName() async {
    await resolveTestCode('''
void f() {
  var abc = 0;
}
''');
    await assertHasAssistAt('bc', '''
void f() {
  int abc = 0;
}
''');
  }

  Future<void> test_local_onVar() async {
    await resolveTestCode('''
void f() {
  var v = 0;
}
''');
    await assertHasAssistAt('var ', '''
void f() {
  int v = 0;
}
''');
  }

  Future<void> test_local_recordType() async {
    await resolveTestCode('''
void f() {
  var v = (x: 0, y: 0);
}
''');
    await assertHasAssistAt('v =', '''
void f() {
  ({int x, int y}) v = (x: 0, y: 0);
}
''');
  }

  Future<void> test_local_unknown() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
void f() {
  var v = unknownVar;
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_parameter() async {
    await resolveTestCode('''
foo(f(int p)) {}
void f() {
  foo((test) {});
}
''');
    await assertHasAssistAt('test', '''
foo(f(int p)) {}
void f() {
  foo((int test) {});
}
''');
  }

  Future<void> test_parameter_final_type_noName() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
typedef F = void Function(final int);
''');
    await assertNoAssistAt('final');
  }

  @FailingTest(reason: '''
This functionality is disabled in `AddTypeAnnotation._forSimpleFormalParameter`
because `writeType` is writing the names of the parameters when it shouldn't.
''')
  Future<void> test_parameter_functionType() async {
    await resolveTestCode('''
foo(f(void Function(int) p)) {}
void f() {
  foo((test) {});
}
''');
    await assertHasAssistAt('test', '''
foo(f(void Function(int) p)) {}
void f() {
  foo((void Function(int) test) {});
}
''');
  }

  Future<void> test_parameter_hasExplicitType() async {
    await resolveTestCode('''
foo(f(int p)) {}
void f() {
  foo((num test) {});
}
''');
    await assertNoAssistAt('test');
  }

  Future<void> test_parameter_noPropagatedType() async {
    await resolveTestCode('''
foo(f(p)) {}
void f() {
  foo((test) {});
}
''');
    await assertNoAssistAt('test');
  }

  Future<void> test_parameter_recordType() async {
    await resolveTestCode('''
foo(f((int, int) p)) {}
void f() {
  foo((test) {});
}
''');
    await assertHasAssistAt('test', '''
foo(f((int, int) p)) {}
void f() {
  foo(((int, int) test) {});
}
''');
  }

  Future<void> test_privateType_closureParameter() async {
    newFile('$testPackageLibPath/my_lib.dart', '''
library my_lib;
class A {}
class _B extends A {}
foo(f(_B p)) {}
''');
    await resolveTestCode('''
import 'my_lib.dart';
void f() {
  foo((test) {});
}
 ''');
    await assertNoAssistAt('test)');
  }

  Future<void> test_privateType_declaredIdentifier() async {
    newFile('$testPackageLibPath/my_lib.dart', '''
library my_lib;
class A {}
class _B extends A {}
List<_B> getValues() => [];
''');
    await resolveTestCode('''
import 'my_lib.dart';
class A<T> {
  void m() {
    for (var item in getValues()) {
    }
  }
}
''');
    await assertNoAssistAt('var item');
  }

  Future<void> test_privateType_list() async {
    // This is now failing because we're suggesting "List" rather than nothing.
    // Is it really better to produce nothing?
    newFile('$testPackageLibPath/my_lib.dart', '''
library my_lib;
class A {}
class _B extends A {}
List<_B> getValues() => [];
''');
    await resolveTestCode('''
import 'my_lib.dart';
void f() {
  var v = getValues();
}
''');
    await assertHasAssistAt('var ', '''
import 'my_lib.dart';
void f() {
  List v = getValues();
}
''');
  }

  Future<void> test_privateType_sameLibrary() async {
    await resolveTestCode('''
class _A {}
_A getValue() => _A();
void f() {
  var v = getValue();
}
''');
    await assertHasAssistAt('var ', '''
class _A {}
_A getValue() => _A();
void f() {
  _A v = getValue();
}
''');
  }

  Future<void> test_privateType_variable() async {
    newFile('$testPackageLibPath/my_lib.dart', '''
library my_lib;
class A {}
class _B extends A {}
_B getValue() => _B();
''');
    await resolveTestCode('''
import 'my_lib.dart';
void f() {
  var v = getValue();
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_topLevelVariable_int() async {
    await resolveTestCode('''
var v = 0;
''');
    await assertHasAssistAt('var ', '''
int v = 0;
''');
  }

  Future<void> test_topLevelVariable_multiple() async {
    await resolveTestCode('''
var a = 1, v = '';
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_topLevelVariable_noValue() async {
    await resolveTestCode('''
var v;
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_topLevelVariable_record() async {
    await resolveTestCode('''
var v = (a: 1, 2);
''');
    await assertHasAssistAt('var ', '''
(int, {int a}) v = (a: 1, 2);
''');
  }
}
