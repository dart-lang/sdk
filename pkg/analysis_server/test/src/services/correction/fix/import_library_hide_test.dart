// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportLibraryHideMultipleTest);
    defineReflectiveTests(ImportLibraryHideTest);
  });
}

@reflectiveTest
class ImportLibraryHideMultipleTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_COMBINATOR_MULTIPLE;

  Future<void> test_classes() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
''');
    await resolveTestCode(r'''
import 'lib.dart' hide B, C;
void f(A a, B b, C c) {
  print('$a');
}
''');
    await assertHasFix(
      r'''
import 'lib.dart';
void f(A a, B b, C c) {
  print('$a');
}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedClass &&
            testCode.indexOf('B b') == error.offset;
      },
    );
    await assertHasFix(
      r'''
import 'lib.dart';
void f(A a, B b, C c) {
  print('$a');
}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedClass &&
            testCode.indexOf('C c') == error.offset;
      },
    );
  }

  Future<void> test_extensions_aliased_notShown_method_propriety() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E1 on String {
  void m() {}
}
extension E2 on String {
  int get n => 0;
}
void foo() {}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' as lib hide E1, E2, foo;

void f(String s, lib.C c) {
  s.m();
  s.n;
}
''');
    await assertHasFix(
      '''
import 'package:test/lib.dart' as lib hide foo;

void f(String s, lib.C c) {
  s.m();
  s.n;
}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedMethod;
      },
    );
  }

  Future<void> test_extensions_notShown_method_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E1 on String {
  void m() {}
}
extension E2 on String {
  int get n => 0;
}
void foo() {}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E1, E2, foo;

void f(String s, C c) {
  s.m();
  s.n;
}
''');
    await assertHasFix(
      '''
import 'package:test/lib.dart' hide foo;

void f(String s, C c) {
  s.m();
  s.n;
}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedMethod;
      },
    );
  }

  Future<void> test_extensions_notShown_operator_setter_override() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E1 on String {
  String operator -(String other) => this;
}
extension E2 on String {
  set m(int v) {}
}
extension E3 on String {
  String m() => '';
}
void foo() {}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E1, E2, E3, foo;

void f(String s, C c) {
  s - '2';
  s.m = 2;
  E3(s).m();
}
''');
    await assertHasFix(
      '''
import 'package:test/lib.dart' hide foo;

void f(String s, C c) {
  s - '2';
  s.m = 2;
  E3(s).m();
}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedOperator;
      },
    );
  }

  Future<void> test_moreThanTwo() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
class D {}
void foo() {}
''');
    await resolveTestCode(r'''
import 'lib.dart' hide B, C, D, foo;
void f() {
  A? a;
  B? b;
  C? c;
  D? d;
  print('$a $b $c $d');
}
''');
    await assertHasFix(
      r'''
import 'lib.dart' hide foo;
void f() {
  A? a;
  B? b;
  C? c;
  D? d;
  print('$a $b $c $d');
}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedClass &&
            testCode.indexOf('B?') == error.offset;
      },
    );
  }

  Future<void> test_sdk() async {
    await resolveTestCode(r'''
import 'dart:collection' hide IterableMixin, LinkedHashMap;
void f() {
  HashMap? s = null;
  IterableMixin? i = null;
  LinkedHashMap? f = null;
  print('$s $i $f');
}
''');
    await assertHasFix(
      r'''
import 'dart:collection';
void f() {
  HashMap? s = null;
  IterableMixin? i = null;
  LinkedHashMap? f = null;
  print('$s $i $f');
}
''',
      errorFilter: (error) {
        return testCode.indexOf('IterableMixin?') == error.offset;
      },
    );
  }

  Future<void> test_static_topLevelVariable() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
final A? a;
extension E on int {
  static String m() => '';
}
void foo() {}
''');
    await resolveTestCode(r'''
import 'lib.dart' hide E, a, foo;
void f(A a1) {
  print('$a1 ${E.m()} $a');
}
''');
    await assertHasFix(
      r'''
import 'lib.dart' hide foo;
void f(A a1) {
  print('$a1 ${E.m()} $a');
}
''',
      errorFilter: (error) {
        return error.diagnosticCode ==
                CompileTimeErrorCode.undefinedIdentifier &&
            testCode.indexOf('E.') == error.offset;
      },
    );
    await assertHasFix(
      r'''
import 'lib.dart' hide foo;
void f(A a1) {
  print('$a1 ${E.m()} $a');
}
''',
      errorFilter: (error) {
        return error.diagnosticCode ==
                CompileTimeErrorCode.undefinedIdentifier &&
            testCode.indexOf("a')") == error.offset;
      },
    );
  }
}

@reflectiveTest
class ImportLibraryHideTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_COMBINATOR;

  Future<void> test_extension_aliased_hidden_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' as lib hide E;

void f(String s, lib.C c) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib;

void f(String s, lib.C c) {
  s.m;
}
''');
  }

  Future<void> test_extension_hidden_class() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' as lib hide C;
import 'package:test/lib.dart' hide C;

void f(String s, lib.C c) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib hide C;
import 'package:test/lib.dart';

void f(String s, C c) {
  s.m;
}
''');
  }

  Future<void> test_extension_hidden_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E;

void f(String s, C c) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s, C c) {
  s.m;
}
''');
  }

  Future<void> test_extension_hidden_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  void m() {}
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E;

void f(String s, C c) {
  s.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s, C c) {
  s.m();
}
''');
  }

  Future<void> test_extension_hidden_operator() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  String operator -(String other) => this;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E;

void f(String s, C c) {
  s - '2';
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s, C c) {
  s - '2';
}
''');
  }

  Future<void> test_extension_hidden_setter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  set m(int v) {}
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E;

void f(String s, C c) {
  s.m = 2;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart';

void f(String s, C c) {
  s.m = 2;
}
''');
  }

  Future<void> test_fromPackageLibrary() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestCode(r'''
import 'lib.dart' hide B;
void f() {
  A? a;
  B b;
  print('$a $b');
}
''');
    await assertHasFix(r'''
import 'lib.dart';
void f() {
  A? a;
  B b;
  print('$a $b');
}
''');
  }

  Future<void> test_fromSdkLibrary() async {
    await resolveTestCode(r'''
import 'dart:collection' hide LinkedHashMap;
void f() {
  HashMap? s = null;
  LinkedHashMap? f = null;
  print('$s $f');
}
''');
    await assertHasFix(r'''
import 'dart:collection';
void f() {
  HashMap? s = null;
  LinkedHashMap? f = null;
  print('$s $f');
}
''');
  }

  Future<void> test_lint_active() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
class D {}
''');
    await resolveTestCode(r'''
// ignore: combinators_ordering
import 'lib.dart' hide C, D, B;
void f(A a, C c) {
  print('$a $c');
}
''');
    await assertHasFix(r'''
// ignore: combinators_ordering
import 'lib.dart' hide B, D;
void f(A a, C c) {
  print('$a $c');
}
''');
  }

  // Two hides, one that should be removed entirely and a show that should be
  // updated. Even though the show is not part of these tests, it should be
  // fixed too for making the import correct.
  Future<void> test_multiple_combinators() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
''');
    await resolveTestCode(r'''
// ignore: multiple_combinators
import 'lib.dart' hide B, C show A hide C;
void f(A a, C c) {
  print('$a $c');
}
''');
    await assertHasFix(r'''
// ignore: multiple_combinators
import 'lib.dart' hide B show A, C;
void f(A a, C c) {
  print('$a $c');
}
''');
  }

  Future<void> test_multipleHide_extension_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
class D {}
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' hide E, D;

void f(String s, C c) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' hide D;

void f(String s, C c) {
  s.m;
}
''');
  }

  Future<void> test_override_samePackage() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on int {
  String m() => '';
}
''');
    await resolveTestCode(r'''
import 'lib.dart' hide E;
void f(A a) {
  print('$a ${E(3).m()}');
}
''');
    await assertHasFix(r'''
import 'lib.dart';
void f(A a) {
  print('$a ${E(3).m()}');
}
''');
  }

  Future<void> test_relativeImport() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  void m() {}
}
''');
    await resolveTestCode('''
import 'lib.dart' as lib hide E;

void f(String s, lib.C c) {
  s.m();
}
''');
    await assertHasFix('''
import 'lib.dart' as lib;

void f(String s, lib.C c) {
  s.m();
}
''', matchFixMessage: "Import 'E' from lib.dart");
  }

  Future<void> test_static_samePackage() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode(r'''
import 'lib.dart' hide E;
void f(A a) {
  print('$a ${E.m()}');
}
''');
    await assertHasFix(r'''
import 'lib.dart';
void f(A a) {
  print('$a ${E.m()}');
}
''');
  }
}
