// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(AddTypeAnnotationTest);
    defineReflectiveTests(AlwaysSpecifyTypesBulkTest);
    defineReflectiveTests(AlwaysSpecifyTypesInFileTest);
    defineReflectiveTests(AlwaysSpecifyTypesLintTest);
    defineReflectiveTests(PreferTypingUninitializedVariablesBulkTest);
    defineReflectiveTests(PreferTypingUninitializedVariablesInFileTest);
    defineReflectiveTests(PreferTypingUninitializedVariablesLintTest);
    defineReflectiveTests(TypeAnnotatePublicAPIsBulkTest);
    defineReflectiveTests(TypeAnnotatePublicAPIsInFileTest);
    defineReflectiveTests(TypeAnnotatePublicAPIsLintTest);
  });
}

@reflectiveTest
class AddTypeAnnotationTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_TYPE_ANNOTATION;

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
  FixKind get kind => DartFixKind.ADD_TYPE_ANNOTATION;

  @override
  String get lintCode => LintNames.always_specify_types;

  // More coverage in the `add_type_annotation_test.dart` assist test.

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
        lints: [LintNames.prefer_typing_uninitialized_variables]);
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
  FixKind get kind => DartFixKind.ADD_TYPE_ANNOTATION;

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
  FixKind get kind => DartFixKind.ADD_TYPE_ANNOTATION;

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
