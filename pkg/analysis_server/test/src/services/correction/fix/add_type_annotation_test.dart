// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(AddTypeAnnotationTest);
    defineReflectiveTests(AlwaysSpecifyTypesBulkTest);
    defineReflectiveTests(AlwaysSpecifyTypesInFileTest);
    defineReflectiveTests(AlwaysSpecifyTypesLintTest);
    defineReflectiveTests(PreferTypingUninitializedVariablesBulkTest);
    defineReflectiveTests(PreferTypingUninitializedVariablesInFileTest);
    defineReflectiveTests(PreferTypingUninitializedVariablesLintTest);
    defineReflectiveTests(SpecifyNonObviousLocalVariableTypesBulkTest);
    defineReflectiveTests(SpecifyNonObviousLocalVariableTypesInFileTest);
    defineReflectiveTests(SpecifyNonObviousLocalVariableTypesLintTest);
    defineReflectiveTests(TypeAnnotatePublicAPIsBulkTest);
    defineReflectiveTests(TypeAnnotatePublicAPIsInFileTest);
    defineReflectiveTests(TypeAnnotatePublicAPIsLintTest);
  });
}

@reflectiveTest
class AddTypeAnnotationTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.addTypeAnnotation;

  Future<void> test_missingFieldType() async {
    // MISSING_CONST_FINAL_VAR_OR_TYPE
    await resolveTestCode('''
class A {
  f = 0;
}
''');
    await assertHasFix('''
class A {
  int f = 0;
}
''');
  }

  Future<void> test_missingStaticFieldType() async {
    // MISSING_CONST_FINAL_VAR_OR_TYPE
    await resolveTestCode('''
class A {
  static f = 0;
}
''');
    await assertHasFix('''
class A {
  static int f = 0;
}
''');
  }
}

@reflectiveTest
class AlwaysSpecifyTypesBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.always_specify_types;

  Future<void> test_bulk() async {
    await resolveTestCode('''
final a = 0;
class A {
  final b = 1;
}
''');
    await assertHasFix('''
final int a = 0;
class A {
  final int b = 1;
}
''');
  }
}

@reflectiveTest
class AlwaysSpecifyTypesInFileTest extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(lints: [LintNames.always_specify_types]);
    await resolveTestCode(r'''
final a = 0;
class A {
  final b = 1;
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
final int a = 0;
class A {
  final int b = 1;
}
''');
  }
}

@reflectiveTest
class AlwaysSpecifyTypesLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.addTypeAnnotation;

  @override
  String get lintCode => LintNames.always_specify_types;

  Future<void> test_field() async {
    await resolveTestCode('''
class A {
  final f = 0;
}
''');
    await assertHasFix('''
class A {
  final int f = 0;
}
''');
  }

  Future<void> test_listLiteral() async {
    await resolveTestCode('''
void f() {
  [0];
}
''');
    await assertHasFix('''
void f() {
  <int>[0];
}
''');
  }

  Future<void> test_listPattern_destructured() async {
    await resolveTestCode('''
f() {
  var [a] = <int>[1];
  print(a);
}
''');
    await assertHasFix('''
f() {
  var [int a] = <int>[1];
  print(a);
}
''');
  }

  Future<void> test_listPattern_destructured_listLiteral() async {
    await resolveTestCode('''
f() {
  var [int a] = [1];
  print(a);
}
''');
    await assertHasFix('''
f() {
  var [int a] = <int>[1];
  print(a);
}
''');
  }

  Future<void> test_mapPattern_destructured() async {
    await resolveTestCode('''
f() {
  var {'a': a} = <String, int>{'a': 1};
  print(a);
}
''');
    await assertHasFix('''
f() {
  var {'a': int a} = <String, int>{'a': 1};
  print(a);
}
''');
  }

  Future<void> test_mapPattern_destructured_mapLiteral() async {
    await resolveTestCode('''
f() {
  var {'a': int a} = {'a': 1};
  print(a);
}
''');
    await assertHasFix('''
f() {
  var {'a': int a} = <String, int>{'a': 1};
  print(a);
}
''');
  }

  Future<void> test_objectPattern_switch_final() async {
    await resolveTestCode('''
class A {
  int a;
  A(this.a);
}
f() {
  switch (A(1)) {
    case A(a: >0 && final b): print(b);
  }
}
''');
    await assertHasFix('''
class A {
  int a;
  A(this.a);
}
f() {
  switch (A(1)) {
    case A(a: >0 && final int b): print(b);
  }
}
''');
  }

  // More coverage in the `add_type_annotation_test.dart` assist test.

  Future<void> test_privateType_list() async {
    // This would work for impl types in a package, not just private types.
    newFile('$testPackageLibPath/my_lib.dart', '''
library my_lib;
class A {}
class _B extends A {}
List<_B> getValues() => [];
''');
    await resolveTestCode('''
import 'my_lib.dart';
void f() {
  var _ = getValues();
}
''');
    await assertHasFix('''
import 'my_lib.dart';
void f() {
  List<A> _ = getValues();
}
''');
  }

  Future<void> test_recordPattern_switch() async {
    await resolveTestCode('''
f() {
  switch ((1, 2)) {
    case (final a, int b): print(a); print(b);
  }
}
''');
    await assertHasFix('''
f() {
  switch ((1, 2)) {
    case (final int a, int b): print(a); print(b);
  }
}
''');
  }

  Future<void> test_recordPattern_switch_var() async {
    await resolveTestCode('''
f() {
  switch ((1, 2)) {
    case (int a, var b): print(a); print(b);
  }
}
''');
    await assertHasFix('''
f() {
  switch ((1, 2)) {
    case (int a, int b): print(a); print(b);
  }
}
''');
  }

  Future<void> test_setOrMapLiteral_ambiguous() async {
    await resolveTestCode('''
void f() {
  ({0, 1:2});
}
''');
    await assertNoFix(filter: lintNameFilter(LintNames.always_specify_types));
  }

  Future<void> test_setOrMapLiteral_map() async {
    await resolveTestCode('''
void f() {
  ({0: true});
}
''');
    await assertHasFix(r'''
void f() {
  (<int, bool>{0: true});
}
''');
  }

  Future<void> test_setOrMapLiteral_map_const() async {
    await resolveTestCode('''
void f() {
  (const {0: true});
}
''');
    await assertHasFix(r'''
void f() {
  (const <int, bool>{0: true});
}
''');
  }

  Future<void> test_setOrMapLiteral_set() async {
    await resolveTestCode('''
void f() {
  ({0, 1, 2});
}
''');
    await assertHasFix(r'''
void f() {
  (<int>{0, 1, 2});
}
''');
  }

  Future<void> test_setOrMapLiteral_set_const() async {
    await resolveTestCode('''
void f() {
  (const {0, 1, 2});
}
''');
    await assertHasFix(r'''
void f() {
  (const <int>{0, 1, 2});
}
''');
  }
}

@reflectiveTest
class PreferTypingUninitializedVariablesBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.prefer_typing_uninitialized_variables;

  Future<void> test_bulk() async {
    await resolveTestCode('''
void f() {
  var a, b;
  a = 0;
  b = 1;
  print(a);
  print(b);
}
''');
    await assertHasFix('''
void f() {
  int a, b;
  a = 0;
  b = 1;
  print(a);
  print(b);
}
''');
  }
}

@reflectiveTest
class PreferTypingUninitializedVariablesInFileTest
    extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(
      lints: [LintNames.prefer_typing_uninitialized_variables],
    );
    await resolveTestCode(r'''
void f() {
  var a, b;
  a = 0;
  b = 1;
  print(a);
  print(b);
}
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
void f() {
  int a, b;
  a = 0;
  b = 1;
  print(a);
  print(b);
}
''');
  }
}

@reflectiveTest
class PreferTypingUninitializedVariablesLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.addTypeAnnotation;

  @override
  String get lintCode => LintNames.prefer_typing_uninitialized_variables;

  // More coverage in the `add_type_annotation_test.dart` assist test.

  Future<void> test_local() async {
    await resolveTestCode('''
void f() {
  var l;
  l = 0;
  print(l);
}
''');
    await assertHasFix('''
void f() {
  int l;
  l = 0;
  print(l);
}
''');
  }
}

@reflectiveTest
class SpecifyNonObviousLocalVariableTypesBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.specify_nonobvious_local_variable_types;

  Future<void> test_bulk() async {
    await resolveTestCode('''
void main() {
  final a = x;
  var b = x;
}
int x = 1;
''');
    await assertHasFix('''
void main() {
  final int a = x;
  int b = x;
}
int x = 1;
''');
  }
}

@reflectiveTest
class SpecifyNonObviousLocalVariableTypesInFileTest
    extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(
      lints: [LintNames.specify_nonobvious_local_variable_types],
    );
    await resolveTestCode(r'''
f() {
  var x = g(0), y = g('');
  return (x, y);
}

T g<T>(T d) => d;
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(0));
  }
}

@reflectiveTest
class SpecifyNonObviousLocalVariableTypesLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.addTypeAnnotation;

  @override
  String get lintCode => LintNames.specify_nonobvious_local_variable_types;

  Future<void> test_listPattern_destructured() async {
    await resolveTestCode('''
f() {
  var [a] = [1, 1.5];
  print(a);
}
''');
    await assertHasFix('''
f() {
  var [num a] = [1, 1.5];
  print(a);
}
''');
  }

  Future<void> test_local_variable() async {
    await resolveTestCode('''
int f() {
  final f = x;
  return f;
}
int x = 1;
''');
    await assertHasFix('''
int f() {
  final int f = x;
  return f;
}
int x = 1;
''');
  }

  Future<void> test_mapPattern_destructured() async {
    await resolveTestCode('''
f() {
  var {'a': a} = {'a': x};
  print(a);
}
int x = 1;
''');
    await assertHasFix('''
f() {
  var {'a': int a} = {'a': x};
  print(a);
}
int x = 1;
''');
  }

  Future<void> test_objectPattern_switch_final() async {
    await resolveTestCode('''
class A {
  int a;
  A(this.a);
}
var a = A(1);
f() {
  switch (a) {
    case A(a: >0 && final b): print(b);
  }
 }
''');
    await assertHasFix('''
class A {
  int a;
  A(this.a);
}
var a = A(1);
f() {
  switch (a) {
    case A(a: >0 && final int b): print(b);
  }
 }
''');
  }

  Future<void> test_recordPattern_switch() async {
    await resolveTestCode('''
f() {
  switch ((1, x)) {
    case (final a, int b): print(a); print(b);
  }
}
int x = 2;
''');
    await assertHasFix('''
f() {
  switch ((1, x)) {
    case (final int a, int b): print(a); print(b);
  }
}
int x = 2;
''');
  }

  Future<void> test_recordPattern_switch_var() async {
    await resolveTestCode('''
f() {
  switch ((1, x)) {
    case (int a, var b): print(a); print(b);
  }
}
int x = 2;
''');
    await assertHasFix('''
f() {
  switch ((1, x)) {
    case (int a, int b): print(a); print(b);
  }
}
int x = 2;
''');
  }
}

@reflectiveTest
class TypeAnnotatePublicAPIsBulkTest extends BulkFixProcessorTest {
  @override
  String get lintCode => LintNames.type_annotate_public_apis;

  Future<void> test_bulk() async {
    await resolveTestCode('''
var a = '', b = '';
''');
    await assertHasFix('''
String a = '', b = '';
''');
  }
}

@reflectiveTest
class TypeAnnotatePublicAPIsInFileTest extends FixInFileProcessorTest {
  Future<void> test_File() async {
    createAnalysisOptionsFile(lints: [LintNames.type_annotate_public_apis]);
    await resolveTestCode(r'''
var a = '', b = '';
''');
    var fixes = await getFixesForFirstError();
    expect(fixes, hasLength(1));
    assertProduces(fixes.first, r'''
String a = '', b = '';
''');
  }
}

@reflectiveTest
class TypeAnnotatePublicAPIsLintTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.addTypeAnnotation;

  @override
  String get lintCode => LintNames.type_annotate_public_apis;

  Future<void> test_local() async {
    await resolveTestCode('''
var a = '';
''');
    await assertHasFix('''
String a = '';
''');
  }
}
