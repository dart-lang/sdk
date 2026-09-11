// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryPriorityTest);
    defineReflectiveTests(ImportLibraryProject1DocTest);
    defineReflectiveTests(ImportLibraryProject1PrefixedTest);
    defineReflectiveTests(ImportLibraryProject1PrefixedWithShowTest);
    defineReflectiveTests(ImportLibraryProject1Test);
    defineReflectiveTests(ImportLibraryProject1WithShowTest);
    defineReflectiveTests(ImportLibraryProject2DocTest);
    defineReflectiveTests(ImportLibraryProject2PrefixedTest);
    defineReflectiveTests(ImportLibraryProject2PrefixedWithShowTest);
    defineReflectiveTests(ImportLibraryProject2Test);
    defineReflectiveTests(ImportLibraryProject2WithShowTest);
    defineReflectiveTests(ImportLibraryProject3DocTest);
    defineReflectiveTests(ImportLibraryProject3PrefixedTest);
    defineReflectiveTests(ImportLibraryProject3PrefixedWithShowTest);
    defineReflectiveTests(ImportLibraryProject3Test);
    defineReflectiveTests(ImportLibraryProject3WithShowTest);
    defineReflectiveTests(ImportLibraryProject4DocTest);
    defineReflectiveTests(ImportLibraryProject4Test);
  });
}

@reflectiveTest
class ImportLibraryPriorityTest extends FixPriorityTest {
  Future<void> test_project1_project2_project3_project4() async {
    newFile('$testPackageLibPath/a1.dart', '''
class Foo {}
''');
    newFile('$testPackageLibPath/src/x2.dart', '''
class Foo {}
''');
    newFile('$testPackageLibPath/a2.dart', '''
export 'src/x2.dart';
''');
    newFile('$testPackageLibPath/a4.dart', '''
@deprecated
class Foo {}
''');
    await resolveTestCode('''
void f() {
  Foo? a;
  print('\$a');
}
''');
    await assertFixPriorityOrder([
      DartFixKind.importLibraryProject1,
      DartFixKind.importLibraryProject1Show,
      DartFixKind.importLibraryProject2,
      DartFixKind.importLibraryProject2Show,
      DartFixKind.importLibraryProject3,
      DartFixKind.importLibraryProject3Show,
      DartFixKind.importLibraryProject4,
      DartFixKind.importLibraryProject4Show,
    ]);
  }

  Future<void> test_project1Doc_project2Doc_project3Doc_project4Doc() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/a1.dart', '''
class Foo {}
''');
    newFile('$testPackageLibPath/src/x2.dart', '''
class Foo {}
''');
    newFile('$testPackageLibPath/a2.dart', '''
export 'src/x2.dart';
''');
    newFile('$testPackageLibPath/a4.dart', '''
@deprecated
class Foo {}
''');
    await resolveTestCode('''
/// [Foo]
void f() {}
''');
    await assertFixPriorityOrder([
      DartFixKind.importLibraryProject1Doc,
      DartFixKind.importLibraryProject1,
      DartFixKind.importLibraryProject2Doc,
      DartFixKind.importLibraryProject3Doc,
      DartFixKind.importLibraryProject2,
      DartFixKind.importLibraryProject3,
      DartFixKind.importLibraryProject4Doc,
      DartFixKind.importLibraryProject4,
    ]);
  }

  Future<void>
  test_project1Prefixed_project2Prefixed_project3Prefixed_project4Prefixed() async {
    newFile('$testPackageLibPath/a1.dart', '''
class Foo {}
''');
    newFile('$testPackageLibPath/src/x2.dart', '''
class Foo {}
''');
    newFile('$testPackageLibPath/a2.dart', '''
export 'src/x2.dart';
''');
    newFile('$testPackageLibPath/a4.dart', '''
@deprecated
class Foo {}
''');
    await resolveTestCode('''
void f() {
  prefix.Foo? a;
  print('\$a');
}
''');
    await assertFixPriorityOrder([
      DartFixKind.importLibraryProject1Prefixed,
      DartFixKind.importLibraryProject1PrefixedShow,
      DartFixKind.importLibraryProject2Prefixed,
      DartFixKind.importLibraryProject2PrefixedShow,
      DartFixKind.importLibraryProject3Prefixed,
      DartFixKind.importLibraryProject3PrefixedShow,
      DartFixKind.importLibraryProject4Prefixed,
      DartFixKind.importLibraryProject4PrefixedShow,
    ]);
  }

  Future<void> test_sdkAndCombinatorFirst_project1() async {
    newFile('$testPackageLibPath/lib.dart', '''
int max(int a) => a;
''');
    await resolveTestCode('''
import 'dart:math' hide max;

void f() {
  max();
}
''');
    await assertFixPriorityOrder([
      DartFixKind.importLibraryCombinator,
      DartFixKind.importLibraryProject1,
      DartFixKind.importLibraryProject1Show,
    ]);
  }
}

@reflectiveTest
class ImportLibraryProject1DocTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject1Doc;

  Future<void> test_extension_name() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
extension Ext on int {}
''');
    await resolveTestCode('''
/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
/// @docImport 'package:test/lib.dart';
library;

/// This should import [Ext].
void f() {}
''');
  }

  Future<void> test_notCommentReference() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
void f() {
  Test t;
  print(t);
}
''');
    await assertNoFix();
  }

  Future<void> test_withClass_commentReference() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/// [Test]
void f() {}
''');
    await assertHasFix('''
/// @docImport 'package:test/lib.dart';
library;

/// [Test]
void f() {}
''');
  }

  Future<void>
  test_withClass_commentReference_existingLibraryDirective() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
library;

/// [Test]
void f() {}
''');
    await assertHasFix('''
/// @docImport 'package:test/lib.dart';
library;

/// [Test]
void f() {}
''');
  }

  Future<void>
  test_withClass_commentReference_existingLibraryDirective_docImports_blockComment() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/**
 * @docImport 'dart:math';
 */
library;

/// [Test]
void f() {}
''');
    await assertHasFix('''
/**
 * @docImport 'dart:math';
 *
 * @docImport 'package:test/lib.dart';
 */
library;

/// [Test]
void f() {}
''');
  }

  Future<void>
  test_withClass_commentReference_existingLibraryDirective_docImports_blockComment_weird() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/** @docImport 'dart:math'; */
library;

/// [Test]
void f() {}
''');
    // The existing `@docImport` isn't recognized as one here, since it shares
    // its line with both the opening `/**` and the closing `*/`. The new
    // directive is still added, which pushes that line down below the `/**`.
    await assertHasFix('''
/**
 * @docImport 'package:test/lib.dart';
 *
 * @docImport 'dart:math'; */
library;

/// [Test]
void f() {}
''');
  }

  Future<void>
  test_withClass_commentReference_existingLibraryDirective_docImports_directivesOrdering() async {
    createAnalysisOptionsFile(
      lints: [LintNames.comment_references, LintNames.directives_ordering],
    );
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/// @docImport 'dart:async';
/// @docImport 'dart:math';
library;

/// [Test]
void f() {}
''');
    await assertHasFix('''
/// @docImport 'dart:async';
/// @docImport 'dart:math';
///
/// @docImport 'package:test/lib.dart';
library;

/// [Test]
void f() {}
''');
  }

  Future<void>
  test_withClass_commentReference_existingLibraryDirective_docImports_directivesOrdering_package() async {
    createAnalysisOptionsFile(
      lints: [LintNames.comment_references, LintNames.directives_ordering],
    );
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/// @docImport 'dart:async';
library;

/// [Test]
void f() {}
''');
    await assertHasFix('''
/// @docImport 'dart:async';
///
/// @docImport 'package:test/lib.dart';
library;

/// [Test]
void f() {}
''');
  }

  Future<void>
  test_withClass_commentReference_existingLibraryDirective_docImports_directivesOrdering_relative() async {
    createAnalysisOptionsFile(
      lints: [
        LintNames.comment_references,
        LintNames.directives_ordering,
        LintNames.prefer_relative_imports,
      ],
    );
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    newFile('$testPackageLibPath/a.dart', '''
class Foo {
  const Foo(int p);
}
''');
    await resolveTestCode('''
/// @docImport 'dart:async';
/// @docImport 'package:test/lib.dart';
library;

/// [Foo]
void f() {}
''');
    await assertHasFix('''
/// @docImport 'dart:async';
/// @docImport 'package:test/lib.dart';
///
/// @docImport 'a.dart';
library;

/// [Foo]
void f() {}
''');
  }

  Future<void>
  test_withClass_commentReference_existingLibraryDirective_withDocs() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/// Something else here.
library;

/// [Test]
void f() {}
''');
    await assertHasFix('''
/// @docImport 'package:test/lib.dart';
///
/// Something else here.
library;

/// [Test]
void f() {}
''');
  }

  Future<void>
  test_withClass_commentReference_existingLibraryDirective_withDocs_blockComment() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/**
 * Something here
 */
library;

/// [Test]
void f() {}
''');
    await assertHasFix('''
/**
 * @docImport 'package:test/lib.dart';
 *
 * Something here
 */
library;

/// [Test]
void f() {}
''');
  }

  Future<void> test_withClass_commentReference_needsPrefix() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/// [p.Test]
void f() {}
''');
    await assertNoFix();
  }

  Future<void> test_withFunction_commentReference() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
void test() {}
''');
    await resolveTestCode('''
/// [test]
void f() {}
''');
    await assertHasFix('''
/// @docImport 'package:test/lib.dart';
library;

/// [test]
void f() {}
''');
  }

  Future<void> test_withInitialDocs() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
extension Ext on int {}
''');
    await resolveTestCode('''
// Something here.

/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
// Something here.

/// @docImport 'package:test/lib.dart';
library;

/// This should import [Ext].
void f() {}
''');
  }

  Future<void> test_withTopLevelVariable_commentReference() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
const test = 0;
''');
    await resolveTestCode('''
/// [test]
void f() {}
''');
    await assertHasFix('''
/// @docImport 'package:test/lib.dart';
library;

/// [test]
void f() {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject1PrefixedTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject1Prefixed;

  Future<void> test_annotation_constructor() async {
    newFile('$testPackageLibPath/a.dart', '''
class MyAnnotation {
  const MyAnnotation();
}
''');
    await resolveTestCode('''
@a.MyAnnotation()
void f() {}
''');
    await assertHasFix('''
import 'package:test/a.dart' as a;

@a.MyAnnotation()
void f() {}
''');
  }

  Future<void> test_annotation_variable() async {
    newFile('$testPackageLibPath/a.dart', '''
const myAnnotation = 42;
''');
    await resolveTestCode('''
@a.myAnnotation
void f() {}
''');
    await assertHasFix('''
import 'package:test/a.dart' as a;

@a.myAnnotation
void f() {}
''');
  }

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await resolveTestCode('''
void f() {
  prefix.A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix;

void f() {
  prefix.A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib.dart', '''
const value = 0;
''');
    await resolveTestCode('''
void f() {
  lib.value;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib;

void f() {
  lib.value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension A on int {}
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(a.A a) {}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as a;

void f(a.A a) {}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib.dart', '''
void foo() {}
''');
    await resolveTestCode('''
void f() {
  prefix.foo();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix;

void f() {
  prefix.foo();
}
''');
  }

  Future<void> test_withEnum_value() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E { one, two }
''');
    await resolveTestCode('''
void f() {
  lib.E.one;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib;

void f() {
  lib.E.one;
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject1PrefixedWithShowTest
    extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject1PrefixedShow;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await resolveTestCode('''
void f() {
  prefix.A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix show A;

void f() {
  prefix.A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib.dart', '''
const value = 0;
''');
    await resolveTestCode('''
void f() {
  lib.value;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib show value;

void f() {
  lib.value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension A on int {}
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix show A;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(a.A a) {}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as a show A;

void f(a.A a) {}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix show A;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib.dart', '''
void foo() {}
''');
    await resolveTestCode('''
void f() {
  prefix.foo();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as prefix show foo;

void f() {
  prefix.foo();
}
''');
  }

  Future<void> test_withEnum_value() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E { one, two }
''');
    await resolveTestCode('''
void f() {
  lib.E.one;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib show E;

void f() {
  lib.E.one;
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject1Test extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject1;

  Future<void> test_alreadyImported_package() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestCode('''
import 'lib.dart' show A;
void f() {
  A? a;
  B? b;
  print('\$a \$b');
}
''');
    await assertNoFix();
  }

  Future<void> test_classContainingWith() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await resolveTestCode('''
class B extends A with M {}

mixin M {}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

class B extends A with M {}

mixin M {}
''');
  }

  Future<void> test_extension_name() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
extension Ext on int {}
''');
    await resolveTestCode('''
/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

/// This should import [Ext].
void f() {}
''');
  }

  Future<void> test_extension_notImported_binaryOperator() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  String operator -(String other) => this;
}
''');
    await resolveTestCode('''
void f(String s) {
  s - '2';
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  s - '2';
}
''');
  }

  Future<void> test_extension_notImported_field_onThisType_fromClass() async {
    newFile('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on C {
  int m() => 0;
}
''');
    newFile('$testPackageLibPath/lib1.dart', '''
class C {}
''');
    await resolveTestCode('''
import 'package:test/lib1.dart';

class D extends C {
  int f = m();
}
''');
    await assertHasFix('''
import 'package:test/lib1.dart';
import 'package:test/lib2.dart';

class D extends C {
  int f = m();
}
''');
  }

  Future<void> test_extension_notImported_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
void f(String s) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  s.m;
}
''');
  }

  Future<void> test_extension_notImported_getter_nullAware() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
void f(String? s) {
  s?.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String? s) {
  s?.m;
}
''');
  }

  Future<void> test_extension_notImported_getter_this() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on A {
  int get g => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib1.dart';

class B extends A {
  void f() {
    g;
  }
}
''');
    await assertHasFix('''
import 'package:test/lib1.dart';
import 'package:test/lib2.dart';

class B extends A {
  void f() {
    g;
  }
}
''');
  }

  Future<void> test_extension_notImported_lint() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on int {
  void m() {}
}
''');
    await resolveTestCode('''
void f(int o) {
  o.m();
}
''');
    await assertHasFix('''
import 'lib.dart';

void f(int o) {
  o.m();
}
''', fixMessageContains: "'lib.dart'");
  }

  Future<void> test_extension_notImported_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  void m() {}
}
''');
    await resolveTestCode('''
void f(String s) {
  s.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  s.m();
}
''');
  }

  Future<void> test_extension_notImported_method_extendsGeneric() async {
    newFile('$testPackageLibPath/lib.dart', '''
import 'package:test/lib1.dart';

extension E<T extends num> on List<T> {
  void m() {}
}
''');
    await resolveTestCode('''
void f(List<int> l) {
  l.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(List<int> l) {
  l.m();
}
''');
  }

  Future<void> test_extension_notImported_method_nullAware() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  void m() {}
}
''');
    await resolveTestCode('''
void f(String? s) {
  s?.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String? s) {
  s?.m();
}
''');
  }

  Future<void> test_extension_notImported_method_onThisType_fromClass() async {
    newFile('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on C {
  void m() {}
}
''');
    newFile('$testPackageLibPath/lib1.dart', '''
class C {}
''');
    await resolveTestCode('''
import 'package:test/lib1.dart';

class D extends C {
  void m2() {
    m();
  }
}
''');
    await assertHasFix('''
import 'package:test/lib1.dart';
import 'package:test/lib2.dart';

class D extends C {
  void m2() {
    m();
  }
}
''');
  }

  Future<void>
  test_extension_notImported_method_onThisType_fromExtension() async {
    newFile('$testPackageLibPath/lib2.dart', '''
import 'package:test/lib1.dart';

extension E on C {
  void m() {}
}
''');
    newFile('$testPackageLibPath/lib1.dart', '''
class C {}
''');
    await resolveTestCode('''
import 'package:test/lib1.dart';

extension F on C {
  void m2() {
    m();
  }
}
''');
    await assertHasFix('''
import 'package:test/lib1.dart';
import 'package:test/lib2.dart';

extension F on C {
  void m2() {
    m();
  }
}
''');
  }

  Future<void> test_extension_notImported_setter() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  set m(int v) {}
}
''');
    await resolveTestCode('''
void f(String s) {
  s.m = 2;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  s.m = 2;
}
''');
  }

  Future<void> test_extension_notImported_unaryOperator() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on String {
  String operator ~() => this;
}
''');
    await resolveTestCode('''
void f(String s) {
  ~s;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  ~s;
}
''');
  }

  Future<void> test_extensionType_name_notImported() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type ET(String it) {}
''');
    await resolveTestCode('''
void f(ET s) {}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(ET s) {}
''');
  }

  Future<void> test_extensionType_notImported() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type ET(String it) {}
''');
    await resolveTestCode('''
void f(String s) {
  ET(s);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s) {
  ET(s);
}
''');
  }

  Future<void> test_invalidUri_interpolation() async {
    newFile('$testPackageLibPath/lib.dart', r'''
class Test {
  const Test();
}
''');
    await resolveTestCode(r'''
import 'package:$foo/foo.dart';

void f() {
  Test();
}
''');
    await assertHasFix(r'''
import 'package:test/lib.dart';

import 'package:$foo/foo.dart';

void f() {
  Test();
}
''', filter: (e) => e.diagnosticCode == diag.undefinedFunction);
  }

  Future<void> test_lib() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
class Test {}
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(
          name: 'my_pkg',
          rootFolder: getFolder('$packagesRootPath/my_pkg'),
        ),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');

    await resolveTestCode('''
void f() {
  Test test = null;
  print(test);
}
''');

    await assertHasFix('''
import 'package:my_pkg/a.dart';

void f() {
  Test test = null;
  print(test);
}
''', expectedNumberOfFixesForKind: 1);
  }

  Future<void> test_lib_extension() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
extension E on int {
  static String m() => '';
}
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(
          name: 'my_pkg',
          rootFolder: getFolder('$packagesRootPath/my_pkg'),
        ),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');

    await resolveTestCode('''
f() {
  print(E.m());
}
''');

    await assertHasFix('''
import 'package:my_pkg/a.dart';

f() {
  print(E.m());
}
''', expectedNumberOfFixesForKind: 1);
  }

  Future<void> test_lib_src() async {
    newFile('$packagesRootPath/my_pkg/lib/src/a.dart', '''
class Test {}
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(
          name: 'my_pkg',
          rootFolder: getFolder('$packagesRootPath/my_pkg'),
        ),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
void f() {
  Test test = null;
  print(test);
}
''');
    await assertNoFix();
  }

  Future<void> test_notInLib() async {
    newFile('/home/other/test/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  Test t;
  print(t);
}
''');
    await assertNoFix();
  }

  Future<void> test_pattern() async {
    newFile('$testPackageLibPath/a.dart', '''
extension IntExt on int {
  int get foo => 0;
}
''');

    await resolveTestCode('''
void f(Object o) {
  if (o case int(foo: int())) {}
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f(Object o) {
  if (o case int(foo: int())) {}
}
''');
  }

  Future<void> test_pattern_simplified() async {
    newFile('$testPackageLibPath/a.dart', '''
extension IntExt on int {
  int get foo => 0;
}
''');

    await resolveTestCode('''
void f(Object o) {
  if (o case int(:var foo)) {
    print(foo);
  }
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f(Object o) {
  if (o case int(:var foo)) {
    print(foo);
  }
}
''');
  }

  Future<void> test_relativeDirective() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 2,
      fixMessageContains: "'a.dart'",
    );
    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      fixMessagesContains: ["'package:test/a.dart'", "'a.dart'"],
    );
  }

  Future<void> test_relativeDirective_alwaysUsePackageImports() async {
    createAnalysisOptionsFile(lints: [LintNames.always_use_package_imports]);
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'package:test/a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 1,
      fixMessageContains: "'package:test/a.dart'",
    );
    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 1,
      fixMessagesContains: ["'package:test/a.dart'"],
    );
  }

  Future<void> test_relativeDirective_downOneDirectory() async {
    newFile('$testPackageLibPath/dir/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'dir/a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 2,
      fixMessageContains: "'dir/a.dart'",
    );
  }

  Future<void> test_relativeDirective_noLint() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'package:test/a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 2,
      fixMessageContains: "'package:test/a.dart'",
    );
    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      fixMessagesContains: ["'package:test/a.dart'", "'a.dart'"],
    );
  }

  Future<void> test_relativeDirective_preferRelativeImports() async {
    createAnalysisOptionsFile(lints: [LintNames.prefer_relative_imports]);
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import 'a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 1,
      fixMessageContains: "'a.dart'",
    );
    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 1,
      fixMessagesContains: ["'a.dart'"],
    );
  }

  Future<void> test_relativeDirective_upOneDirectory() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo {}
''');
    testFilePath = convertPath('$testPackageLibPath/dir/test.dart');
    await resolveTestCode('''
void f() { new Foo(); }
''');
    await assertHasFix(
      '''
import '../a.dart';

void f() { new Foo(); }
''',
      expectedNumberOfFixesForKind: 2,
      fixMessageContains: "'../a.dart'",
    );
  }

  Future<void> test_unchecked_methodInvocation() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on Object? {
  void m() {}
}
''');
    await resolveTestCode('''
void f(Object? o) {
  o.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(Object? o) {
  o.m();
}
''');
  }

  Future<void> test_unchecked_operatorInvocation() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on Object? {
  int operator +(int other) => 0;
}
''');
    await resolveTestCode('''
void f(Object? o) {
  o + 1;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(Object? o) {
  o + 1;
}
''');
  }

  Future<void> test_unchecked_propertyAccess() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension E on Object? {
  int get getter => 0;
}
''');
    await resolveTestCode('''
void f(Object? o) {
  o.getter;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(Object? o) {
  o.getter;
}
''');
  }

  Future<void> test_withClass_annotation() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
@Test(0)
void f() {}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

@Test(0)
void f() {}
''');
  }

  Future<void> test_withClass_catchClause() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  try {
    print(1);
  } on Test { // ignore: nullable_type_in_catch_clause
    print(2);
  }
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  try {
    print(1);
  } on Test { // ignore: nullable_type_in_catch_clause
    print(2);
  }
}
''');
  }

  Future<void> test_withClass_commentReference() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test(int p);
}
''');
    await resolveTestCode('''
/// [Test]
void f() {}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

/// [Test]
void f() {}
''');
  }

  /// See https://github.com/dart-lang/sdk/issues/42645.
  Future<void> test_withClass_extendsClause() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
class A extends Test {}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

class A extends Test {}
''');
  }

  Future<void> test_withClass_hasOtherLibraryWithPrefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class One {}
''');
    newFile('$testPackageLibPath/b.dart', '''
class One {}
class Two {}
''');
    await resolveTestCode('''
import 'package:test/b.dart' show Two;
main () {
  new Two();
  new One();
}
''');
    await assertHasFix('''
import 'package:test/a.dart';
import 'package:test/b.dart' show Two;
main () {
  new Two();
  new One();
}
''');
  }

  Future<void> test_withClass_inParentFolder() async {
    testFilePath = convertPath('/home/test/bin/aaa/test.dart');
    newFile('/home/test/bin/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import '../lib.dart';

void f() {
  Test t = null;
  print(t);
}
''');
  }

  Future<void> test_withClass_inRelativeFolder() async {
    testFilePath = convertPath('/home/test/bin/test.dart');
    newFile('/home/test/tool/sub/folder/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import '../tool/sub/folder/lib.dart';

void f() {
  Test t = null;
  print(t);
}
''');
  }

  Future<void> test_withClass_inSameFolder() async {
    testFilePath = convertPath('/home/test/bin/test.dart');
    newFile('/home/test/bin/lib.dart', '''
class Test {}
''');
    await resolveTestCode('''
void f() {
  Test t = null;
  print(t);
}
''');
    await assertHasFix('''
import 'lib.dart';

void f() {
  Test t = null;
  print(t);
}
''');
  }

  Future<void> test_withClass_instanceCreation_const() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestCode('''
void f() {
  return const Test();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  return const Test();
}
''');
  }

  Future<void> test_withClass_instanceCreation_const_namedConstructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test.named();
}
''');
    await resolveTestCode('''
void f() {
  const Test.named();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  const Test.named();
}
''');
  }

  Future<void> test_withClass_instanceCreation_implicit() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestCode('''
void f() {
  return Test();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  return Test();
}
''');
  }

  Future<void> test_withClass_instanceCreation_new() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
}
''');
    await resolveTestCode('''
void f() {
  return new Test();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  return new Test();
}
''');
  }

  Future<void> test_withClass_instanceCreation_new_namedConstructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  Test.named();
}
''');
    await resolveTestCode('''
void f() {
  new Test.named();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  new Test.named();
}
''');
  }

  Future<void> test_withClass_pub_other_inLib_dependencies() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dependencies:
  aaa: any
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()..add(name: 'aaa', rootFolder: aaaRoot),
    );

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:aaa/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_other_inLib_devDependencies() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dev_dependencies:
  aaa: any
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()..add(name: 'aaa', rootFolder: aaaRoot),
    );

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertNoFix();
  }

  Future<void> test_withClass_pub_other_inLib_notListed() async {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()..add(name: 'aaa', rootFolder: aaaRoot),
    );

    await resolveTestCode('''
void f(Test t) {}
''');

    // If `aaa` is not in `dependencies`, we will not suggest it.
    await assertNoFix();
  }

  Future<void> test_withClass_pub_other_inTest_dependencies() async {
    _createPackageAaa();
    testFilePath = '$testPackageTestPath/test.dart';
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:aaa/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_other_inTest_devDependencies() async {
    _createPackageAaa();
    testFilePath = '$testPackageTestPath/test.dart';
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:aaa/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_this() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inLib_excludesTest() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageTestPath/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');
    await assertNoFix();
  }

  Future<void> test_withClass_pub_this_inTest_includesTest() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageTestPath/a.dart', r'''
class Test {}
''');

    testFilePath = '$testPackageTestPath/test.dart';
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_simpleIdentifier_lowerCase() async {
    newFile('$testPackageLibPath/lib.dart', '''
class eX {}
''');
    await resolveTestCode('''
void f() {
  eX;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  eX;
}
''');
  }

  Future<void> test_withClass_static_getter_annotation() async {
    newFile('$testPackageLibPath/lib.dart', '''
class Test {
  const Test();
  static const instance = Test();
}
''');
    await resolveTestCode('''
@Test.instance
void f() {}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

@Test.instance
void f() {}
''');
  }

  Future<void> test_withEnum_value() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E { one, two }
''');
    await resolveTestCode('''
void f() {
  E.one;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  E.one;
}
''');
  }

  Future<void> test_withExtension_pub_this() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/a.dart', r'''
extension IntExtension on int {
  int get foo => 0;
}
''');

    await resolveTestCode('''
void f() {
  IntExtension(0).foo;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  IntExtension(0).foo;
}
''');
  }

  Future<void> test_withFunction() async {
    newFile('$testPackageLibPath/lib.dart', '''
myFunction() {}
''');
    await resolveTestCode('''
void f() {
  myFunction();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  myFunction();
}
''');
  }

  Future<void> test_withFunction_functionTopLevelVariable() async {
    newFile('$testPackageLibPath/lib.dart', '''
var myFunction = () {};
''');
    await resolveTestCode('''
void f() {
  myFunction();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  myFunction();
}
''');
  }

  Future<void> test_withFunction_functionTopLevelVariableIdentifier() async {
    newFile('$testPackageLibPath/lib.dart', '''
var myFunction = () {};
''');
    await resolveTestCode('''
void f() {
  myFunction;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  myFunction;
}
''');
  }

  Future<void> test_withFunction_identifier() async {
    newFile('$testPackageLibPath/lib.dart', '''
myFunction() {}
''');
    await resolveTestCode('''
void f() {
  myFunction;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  myFunction;
}
''');
  }

  @failingTest
  Future<void> test_withFunction_nonFunctionType() async {
    newFile('$testPackageLibPath/lib.dart', '''
int zero = 0;
''');
    await resolveTestCode('''
void f() {
  zero();
}
''');
    await assertNoFix();
  }

  Future<void> test_withFunction_unresolvedMethod() async {
    newFile('$testPackageLibPath/lib.dart', '''
myFunction() {}
''');
    await resolveTestCode('''
class A {
  void f() {
    myFunction();
  }
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

class A {
  void f() {
    myFunction();
  }
}
''');
  }

  Future<void> test_withFunctionTypeAlias() async {
    newFile('$testPackageLibPath/lib.dart', '''
typedef MyFunction();
''');
    await resolveTestCode('''
void f() {
  MyFunction t = null;
  print(t);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f() {
  MyFunction t = null;
  print(t);
}
''');
  }

  Future<void> test_withGetter_read() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
''');

    await resolveTestCode('''
void f() {
  foo;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo;
}
''');
  }

  Future<void> test_withGetter_readWrite() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
''');

    await resolveTestCode('''
void f() {
  foo++;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo++;
}
''');
  }

  /// Not really useful, but shows what we have.
  Future<void> test_withGetter_write() async {
    newFile('$testPackageLibPath/a.dart', '''
int get foo => 0;
''');

    await resolveTestCode('''
void f() {
  foo = 0;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo = 0;
}
''');
  }

  Future<void> test_withMixin() async {
    newFile('$testPackageLibPath/lib.dart', '''
mixin Test {}
''');
    await resolveTestCode('''
class X = Object with Test;
''');
    await assertHasFix('''
import 'package:test/lib.dart';

class X = Object with Test;
''');
  }

  Future<void> test_withSetter_assignment() async {
    newFile('$testPackageLibPath/a.dart', '''
set foo(int _) {}
''');

    await resolveTestCode('''
void f() {
  foo = 0;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo = 0;
}
''');
  }

  Future<void> test_withTopLevelVariable_annotation() async {
    newFile('$testPackageLibPath/a.dart', '''
const foo = 0;
''');

    await resolveTestCode('''
@foo
void f() {}
''');

    await assertHasFix('''
import 'package:test/a.dart';

@foo
void f() {}
''');
  }

  Future<void> test_withTopLevelVariable_read() async {
    newFile('$testPackageLibPath/a.dart', '''
var foo = 0;
''');

    await resolveTestCode('''
void f() {
  foo;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo;
}
''');
  }

  Future<void> test_withTopLevelVariable_write() async {
    newFile('$testPackageLibPath/a.dart', '''
var foo = 0;
''');

    await resolveTestCode('''
void f() {
  foo = 0;
}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f() {
  foo = 0;
}
''');
  }

  void _createPackageAaa() {
    var aaaRoot = getFolder('$packagesRootPath/aaa');
    newFile('${aaaRoot.path}/lib/a.dart', '''
class Test {}
''');

    updateTestPubspecFile(r'''
name: test
dependencies:
  aaa: any
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()..add(name: 'aaa', rootFolder: aaaRoot),
    );
  }
}

@reflectiveTest
class ImportLibraryProject1WithShowTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject1Show;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
''');
    await resolveTestCode('''
void f() {
  A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show A;

void f() {
  A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib.dart', '''
const value = 0;
''');
    await resolveTestCode('''
void f() {
  value;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show value;

void f() {
  value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension A on int {}
''');
    await resolveTestCode('''
void f(int i) {
  A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show A;

void f(int i) {
  A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(A a) {}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show A;

void f(A a) {}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib.dart', '''
extension type A(int _) {}
''');
    await resolveTestCode('''
void f(int i) {
  A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show A;

void f(int i) {
  A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib.dart', '''
void foo() {}
''');
    await resolveTestCode('''
void f() {
  foo();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show foo;

void f() {
  foo();
}
''');
  }

  Future<void> test_withEnum_value() async {
    newFile('$testPackageLibPath/lib.dart', '''
enum E { one, two }
''');
    await resolveTestCode('''
void f() {
  E.one;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show E;

void f() {
  E.one;
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2DocTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject2Doc;

  Future<void> test_extension_name() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib1.dart', '''
extension Ext on int {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';''');
    await resolveTestCode('''
/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
/// @docImport 'package:test/lib2.dart';
library;

/// This should import [Ext].
void f() {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2PrefixedTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject2Prefixed;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  prefix.A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix;

void f() {
  prefix.A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const value = 0;
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  lib.value;
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as lib;

void f() {
  lib.value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension A on int {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(a.A a) {}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as a;

void f(a.A a) {}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib1.dart', '''
void foo() {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  prefix.foo();
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix;

void f() {
  prefix.foo();
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2PrefixedWithShowTest
    extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject2PrefixedShow;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  prefix.A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix show A;

void f() {
  prefix.A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const value = 0;
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  lib.value;
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as lib show value;

void f() {
  lib.value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension A on int {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix show A;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(a.A a) {}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as a show A;

void f(a.A a) {}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  prefix.A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix show A;

void f(int i) {
  prefix.A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib1.dart', '''
void foo() {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  prefix.foo();
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' as prefix show foo;

void f() {
  prefix.foo();
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2Test extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject2;

  Future<void> test_extension_name() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/lib1.dart', '''
extension Ext on int {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';''');
    await resolveTestCode('''
/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
import 'package:test/lib2.dart';

/// This should import [Ext].
void f() {}
''');
  }

  Future<void> test_extension_otherPackage_exported_fromSrc() async {
    var pkgRootPath = '$packagesRootPath/aaa';

    newFile('$pkgRootPath/lib/a.dart', r'''
export 'src/b.dart';
''');

    newFile('$pkgRootPath/lib/src/b.dart', r'''
extension IntExtension on int {
  int get foo => 0;
}
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(name: 'aaa', rootFolder: getFolder(pkgRootPath)),
    );

    updateTestPubspecFile('''
dependencies:
  aaa: any
''');

    await resolveTestCode('''
void f() {
  0.foo;
}
''');

    await assertHasFix('''
import 'package:aaa/a.dart';

void f() {
  0.foo;
}
''');
  }

  Future<void> test_lib() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
export 'b.dart';
''');
    newFile('$packagesRootPath/my_pkg/lib/b.dart', '''
class Test {}
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(
          name: 'my_pkg',
          rootFolder: getFolder('$packagesRootPath/my_pkg'),
        ),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
void f() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

void f() {
  Test test = null;
  print(test);
}
''');
  }

  Future<void> test_lib_src() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
export 'src/b.dart';
''');
    newFile('$packagesRootPath/my_pkg/lib/src/b.dart', '''
class Test {}
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(
          name: 'my_pkg',
          rootFolder: getFolder('$packagesRootPath/my_pkg'),
        ),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
void f() {
  Test test = null;
  print(test);
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

void f() {
  Test test = null;
  print(test);
}
''');
  }

  Future<void> test_lib_src_extension() async {
    newFile('$packagesRootPath/my_pkg/lib/a.dart', '''
export 'src/b.dart';
''');
    newFile('$packagesRootPath/my_pkg/lib/src/b.dart', '''
extension E on int {
  static String m() => '';
}
''');

    writeTestPackageConfig2(
      config: PackageConfigFileBuilder()
        ..add(
          name: 'my_pkg',
          rootFolder: getFolder('$packagesRootPath/my_pkg'),
        ),
    );

    newPubspecYamlFile('/home/test', r'''
dependencies:
  my_pkg: any
''');
    await resolveTestCode('''
f() {
  print(E.m());
}
''');
    await assertHasFix('''
import 'package:my_pkg/a.dart';

f() {
  print(E.m());
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject2WithShowTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject2Show;

  Future<void> test_prefixed_class() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  A? a;
  print('\$a');
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show A;

void f() {
  A? a;
  print('\$a');
}
''');
  }

  Future<void> test_prefixed_constant() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const value = 0;
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  value;
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show value;

void f() {
  value;
}
''');
  }

  Future<void> test_prefixed_extension_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension A on int {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show A;

void f(int i) {
  A(i);
}
''');
  }

  Future<void> test_prefixed_extensionType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(A a) {}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show A;

void f(A a) {}
''');
  }

  Future<void> test_prefixed_extensionType_constructor() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension type A(int _) {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f(int i) {
  A(i);
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show A;

void f(int i) {
  A(i);
}
''');
  }

  Future<void> test_prefixed_function() async {
    newFile('$testPackageLibPath/lib1.dart', '''
void foo() {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'package:test/lib1.dart';
''');
    await resolveTestCode('''
void f() {
  foo();
}
''');
    await assertHasFix('''
import 'package:test/lib2.dart' show foo;

void f() {
  foo();
}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3DocTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject3Doc;

  Future<void> test_extension_name() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/src/lib1.dart', '''
extension Ext on int {}
''');
    await resolveTestCode('''
/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
/// @docImport 'package:test/src/lib1.dart';
library;

/// This should import [Ext].
void f() {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3PrefixedTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject3Prefixed;

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    newFile('$testPackageLibPath/src/lib.dart', '''
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode('''
f() {
  print(lib.E.m());
}
''');
    await assertHasFix('''
import 'package:test/src/lib.dart' as lib;

f() {
  print(lib.E.m());
}
''');
  }

  Future<void> test_withClass_pub_this_inLib_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(lib.Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' as lib;

void f(lib.Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inTest_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    testFilePath = '$testPackageTestPath/test.dart';
    await resolveTestCode(r'''
void f(lib.Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' as lib;

void f(lib.Test t) {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3PrefixedWithShowTest
    extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject3PrefixedShow;

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    newFile('$testPackageLibPath/src/lib.dart', '''
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode('''
f() {
  print(lib.E.m());
}
''');
    await assertHasFix('''
import 'package:test/src/lib.dart' as lib show E;

f() {
  print(lib.E.m());
}
''');
  }

  Future<void> test_withClass_pub_this_inLib_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(lib.Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' as lib show Test;

void f(lib.Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inTest_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    testFilePath = '$testPackageTestPath/test.dart';
    await resolveTestCode(r'''
void f(lib.Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' as lib show Test;

void f(lib.Test t) {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3Test extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject3;

  Future<void> test_extension_name() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/src/lib1.dart', '''
extension Ext on int {}
''');
    await resolveTestCode('''
/// This should import [Ext].
void f() {}
''');
    await assertHasFix('''
import 'package:test/src/lib1.dart';

/// This should import [Ext].
void f() {}
''');
  }

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    newFile('$testPackageLibPath/src/lib.dart', '''
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode('''
f() {
  print(E.m());
}
''');
    await assertHasFix('''
import 'package:test/src/lib.dart';

f() {
  print(E.m());
}
''');
  }

  Future<void> test_withClass_pub_this_inLib_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inTest_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    testFilePath = '$testPackageTestPath/test.dart';
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart';

void f(Test t) {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject3WithShowTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject3Show;

  Future<void> test_inLibSrc_thisContextRoot_extension() async {
    newFile('$testPackageLibPath/src/lib.dart', '''
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode('''
f() {
  print(E.m());
}
''');
    await assertHasFix('''
import 'package:test/src/lib.dart' show E;

f() {
  print(E.m());
}
''');
  }

  Future<void> test_withClass_pub_this_inLib_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' show Test;

void f(Test t) {}
''');
  }

  Future<void> test_withClass_pub_this_inTest_includesThisSrc() async {
    updateTestPubspecFile(r'''
name: test
''');

    newFile('$testPackageLibPath/src/a.dart', r'''
class Test {}
''');

    testFilePath = '$testPackageTestPath/test.dart';
    await resolveTestCode(r'''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/src/a.dart' show Test;

void f(Test t) {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject4DocTest extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject4Doc;

  Future<void> test_deprecatedClass_commentReference() async {
    createAnalysisOptionsFile(lints: [LintNames.comment_references]);
    newFile('$testPackageLibPath/a.dart', '''
@deprecated
class Test {}
''');

    await resolveTestCode('''
/// [Test]
void f() {}
''');

    await assertHasFix('''
/// @docImport 'package:test/a.dart';
library;

/// [Test]
void f() {}
''');
  }
}

@reflectiveTest
class ImportLibraryProject4Test extends _ImportLibraryProjectTest {
  @override
  FixKind get kind => DartFixKind.importLibraryProject4;

  Future<void> test_deprecatedClass() async {
    newFile('$testPackageLibPath/a.dart', '''
@deprecated
class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f(Test t) {}
''');
  }

  Future<void> test_deprecatedLibrary() async {
    newFile('$testPackageLibPath/a.dart', '''
@deprecated
library a;

class Test {}
''');

    await resolveTestCode('''
void f(Test t) {}
''');

    await assertHasFix('''
import 'package:test/a.dart';

void f(Test t) {}
''');
  }
}

/// A base class for these tests, which makes `testFilePath` writable, as many
/// of the tests require testing with code in different locations.
abstract class _ImportLibraryProjectTest extends FixProcessorTest {
  @override
  late String testFilePath = '$testPackageLibPath/test.dart';
}
