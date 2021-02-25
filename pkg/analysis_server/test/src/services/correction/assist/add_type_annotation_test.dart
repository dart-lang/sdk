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

  Future<void> test_declaredIdentifier() async {
    await resolveTestCode('''
main(List<String> items) {
  for (var item in items) {
  }
}
''');
    // on identifier
    await assertHasAssistAt('item in', '''
main(List<String> items) {
  for (String item in items) {
  }
}
''');
    // on "for"
    await assertHasAssistAt('for (', '''
main(List<String> items) {
  for (String item in items) {
  }
}
''');
  }

  Future<void> test_declaredIdentifier_addImport_dartUri() async {
    addSource('/home/test/lib/my_lib.dart', r'''
import 'dart:collection';
List<HashMap<String, int>> getMap() => null;
''');
    await resolveTestCode('''
import 'my_lib.dart';
main() {
  for (var map in getMap()) {
  }
}
''');
    await assertHasAssistAt('map in', '''
import 'dart:collection';

import 'my_lib.dart';
main() {
  for (HashMap<String, int> map in getMap()) {
  }
}
''');
  }

  Future<void> test_declaredIdentifier_final() async {
    await resolveTestCode('''
main(List<String> items) {
  for (final item in items) {
  }
}
''');
    await assertHasAssistAt('item in', '''
main(List<String> items) {
  for (final String item in items) {
  }
}
''');
  }

  Future<void> test_declaredIdentifier_generic() async {
    await resolveTestCode('''
class A<T> {
  main(List<List<T>> items) {
    for (var item in items) {
    }
  }
}
''');
    await assertHasAssistAt('item in', '''
class A<T> {
  main(List<List<T>> items) {
    for (List<T> item in items) {
    }
  }
}
''');
  }

  Future<void> test_declaredIdentifier_hasTypeAnnotation() async {
    await resolveTestCode('''
main(List<String> items) {
  for (String item in items) {
  }
}
''');
    await assertNoAssistAt('item in');
  }

  Future<void> test_declaredIdentifier_inForEachBody() async {
    await resolveTestCode('''
main(List<String> items) {
  for (var item in items) {
    42;
  }
}
''');
    await assertNoAssistAt('42;');
  }

  Future<void> test_declaredIdentifier_unknownType() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
main() {
  for (var item in unknownList) {
  }
}
''');
    await assertNoAssistAt('item in');
  }

  Future<void> test_local_addImport_dartUri() async {
    addSource('/home/test/lib/my_lib.dart', r'''
import 'dart:collection';
HashMap<String, int> getMap() => null;
''');
    await resolveTestCode('''
import 'my_lib.dart';
main() {
  var v = getMap();
}
''');
    await assertHasAssistAt('v =', '''
import 'dart:collection';

import 'my_lib.dart';
main() {
  HashMap<String, int> v = getMap();
}
''');
  }

  Future<void> test_local_addImport_notLibraryUnit() async {
    addSource('/home/test/lib/my_lib.dart', r'''
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
main() {
  var /*caret*/v = getMap();
}
''');

    var appPath = convertPath('/home/test/lib/app.dart');
    addSource(appPath, appCode);
    await analyzeTestPackageFiles();
    await resolveTestFile();

    await assertHasAssist('''
part of my_app;
main() {
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
    addSource('/home/test/bin/aa/bbb/lib_a.dart', r'''
class MyClass {}
''');
    addSource('/home/test/bin/ccc/lib_b.dart', r'''
import '../aa/bbb/lib_a.dart';
MyClass newMyClass() => null;
''');
    await resolveTestCode('''
import 'ccc/lib_b.dart';
main() {
  var v = newMyClass();
}
''');
    await assertHasAssistAt('v =', '''
import 'aa/bbb/lib_a.dart';
import 'ccc/lib_b.dart';
main() {
  MyClass v = newMyClass();
}
''');
  }

  Future<void> test_local_bottom() async {
    await resolveTestCode('''
main() {
  var v = throw 42;
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_local_Function() async {
    await resolveTestCode('''
main() {
  var v = () => 1;
}
''');
    await assertHasAssistAt('v =', '''
main() {
  int Function() v = () => 1;
}
''');
  }

  Future<void> test_local_generic_literal() async {
    await resolveTestCode('''
class A {
  main(List<int> items) {
    var v = items;
  }
}
''');
    await assertHasAssistAt('v =', '''
class A {
  main(List<int> items) {
    List<int> v = items;
  }
}
''');
  }

  Future<void> test_local_generic_local() async {
    await resolveTestCode('''
class A<T> {
  main(List<T> items) {
    var v = items;
  }
}
''');
    await assertHasAssistAt('v =', '''
class A<T> {
  main(List<T> items) {
    List<T> v = items;
  }
}
''');
  }

  Future<void> test_local_hasTypeAnnotation() async {
    await resolveTestCode('''
main() {
  int v = 42;
}
''');
    await assertNoAssistAt(' = 42');
  }

  Future<void> test_local_int() async {
    await resolveTestCode('''
main() {
  var v = 0;
}
''');
    await assertHasAssistAt('v =', '''
main() {
  int v = 0;
}
''');
  }

  Future<void> test_local_List() async {
    await resolveTestCode('''
main() {
  var v = <String>[];
}
''');
    await assertHasAssistAt('v =', '''
main() {
  List<String> v = <String>[];
}
''');
  }

  Future<void> test_local_localType() async {
    await resolveTestCode('''
class C {}
C f() => null;
main() {
  var x = f();
}
''');
    await assertHasAssistAt('x =', '''
class C {}
C f() => null;
main() {
  C x = f();
}
''');
  }

  Future<void> test_local_multiple() async {
    await resolveTestCode('''
main() {
  var a = 1, b = '';
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_local_noValue() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
main() {
  var v;
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_local_null() async {
    await resolveTestCode('''
main() {
  var v = null;
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_local_onInitializer() async {
    await resolveTestCode('''
main() {
  var abc = 0;
}
''');
    await assertNoAssistAt('0;');
  }

  Future<void> test_local_onName() async {
    await resolveTestCode('''
main() {
  var abc = 0;
}
''');
    await assertHasAssistAt('bc', '''
main() {
  int abc = 0;
}
''');
  }

  Future<void> test_local_onVar() async {
    await resolveTestCode('''
main() {
  var v = 0;
}
''');
    await assertHasAssistAt('var ', '''
main() {
  int v = 0;
}
''');
  }

  Future<void> test_local_unknown() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
main() {
  var v = unknownVar;
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_parameter() async {
    await resolveTestCode('''
foo(f(int p)) {}
main() {
  foo((test) {});
}
''');
    await assertHasAssistAt('test', '''
foo(f(int p)) {}
main() {
  foo((int test) {});
}
''');
  }

  Future<void> test_parameter_hasExplicitType() async {
    await resolveTestCode('''
foo(f(int p)) {}
main() {
  foo((num test) {});
}
''');
    await assertNoAssistAt('test');
  }

  Future<void> test_parameter_noPropagatedType() async {
    await resolveTestCode('''
foo(f(p)) {}
main() {
  foo((test) {});
}
''');
    await assertNoAssistAt('test');
  }

  Future<void> test_privateType_closureParameter() async {
    addSource('/home/test/lib/my_lib.dart', '''
library my_lib;
class A {}
class _B extends A {}
foo(f(_B p)) {}
''');
    await resolveTestCode('''
import 'my_lib.dart';
main() {
  foo((test) {});
}
 ''');
    await assertNoAssistAt('test)');
  }

  Future<void> test_privateType_declaredIdentifier() async {
    addSource('/home/test/lib/my_lib.dart', '''
library my_lib;
class A {}
class _B extends A {}
List<_B> getValues() => [];
''');
    await resolveTestCode('''
import 'my_lib.dart';
class A<T> {
  main() {
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
    addSource('/home/test/lib/my_lib.dart', '''
library my_lib;
class A {}
class _B extends A {}
List<_B> getValues() => [];
''');
    await resolveTestCode('''
import 'my_lib.dart';
main() {
  var v = getValues();
}
''');
    await assertHasAssistAt('var ', '''
import 'my_lib.dart';
main() {
  List v = getValues();
}
''');
  }

  Future<void> test_privateType_sameLibrary() async {
    await resolveTestCode('''
class _A {}
_A getValue() => _A();
main() {
  var v = getValue();
}
''');
    await assertHasAssistAt('var ', '''
class _A {}
_A getValue() => _A();
main() {
  _A v = getValue();
}
''');
  }

  Future<void> test_privateType_variable() async {
    addSource('/home/test/lib/my_lib.dart', '''
library my_lib;
class A {}
class _B extends A {}
_B getValue() => _B();
''');
    await resolveTestCode('''
import 'my_lib.dart';
main() {
  var v = getValue();
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_topLevelField_int() async {
    await resolveTestCode('''
var V = 0;
''');
    await assertHasAssistAt('var ', '''
int V = 0;
''');
  }

  Future<void> test_topLevelField_multiple() async {
    await resolveTestCode('''
var A = 1, V = '';
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_topLevelField_noValue() async {
    await resolveTestCode('''
var V;
''');
    await assertNoAssistAt('var ');
  }
}
