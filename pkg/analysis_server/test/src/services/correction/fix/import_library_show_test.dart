// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(ImportLibraryShowMultipleTest);
    defineReflectiveTests(ImportLibraryShowTest);
  });
}

@reflectiveTest
class ImportLibraryShowMultipleTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_COMBINATOR_MULTIPLE;

  Future<void> test_classes() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
''');
    await resolveTestCode(r'''
import 'lib.dart' show A;
void f(A a, B b, C c) {
  print('$a');
}
''');
    await assertHasFix(
      r'''
import 'lib.dart' show A, B, C;
void f(A a, B b, C c) {
  print('$a');
}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedClass &&
            testCode.indexOf('B') == error.offset;
      },
    );
    await assertHasFix(
      r'''
import 'lib.dart' show A, C, B;
void f(A a, B b, C c) {
  print('$a');
}
''',
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.undefinedClass &&
            testCode.indexOf('C') == error.offset;
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
''');
    await resolveTestCode('''
import 'package:test/lib.dart' as lib show C;

void f(String s, lib.C c) {
  s.m();
  s.n;
}
''');
    await assertHasFix(
      '''
import 'package:test/lib.dart' as lib show C, E1, E2;

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
''');
    await resolveTestCode('''
import 'package:test/lib.dart' show C;

void f(String s, C c) {
  s.m();
  s.n;
}
''');
    await assertHasFix(
      '''
import 'package:test/lib.dart' show C, E1, E2;

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
''');
    await resolveTestCode('''
import 'package:test/lib.dart' show C;

void f(String s, C c) {
  s - '2';
  s.m = 2;
  E3(s).m();
}
''');
    await assertHasFix(
      '''
import 'package:test/lib.dart' show C, E1, E2, E3;

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
''');
    await resolveTestCode(r'''
import 'lib.dart' show A;
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
import 'lib.dart' show A, B, C, D;
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
            testCode.indexOf('B') == error.offset;
      },
    );
  }

  Future<void> test_sdk() async {
    await resolveTestCode(r'''
import 'dart:collection' show HashMap;
void f() {
  HashMap? s = null;
  IterableMixin? i = null;
  LinkedHashMap? f = null;
  print('$s $i $f');
}
''');
    await assertHasFix(
      r'''
import 'dart:collection' show HashMap, IterableMixin, LinkedHashMap;
void f() {
  HashMap? s = null;
  IterableMixin? i = null;
  LinkedHashMap? f = null;
  print('$s $i $f');
}
''',
      errorFilter: (error) {
        return testCode.indexOf('IterableMixin') == error.offset;
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
''');
    await resolveTestCode(r'''
import 'lib.dart' show A;
void f(A a1) {
  print('$a1 ${E.m()} $a');
}
''');
    await assertHasFix(
      r'''
import 'lib.dart' show A, E, a;
void f(A a1) {
  print('$a1 ${E.m()} $a');
}
''',
      errorFilter: (error) {
        return error.diagnosticCode ==
                CompileTimeErrorCode.undefinedIdentifier &&
            testCode.indexOf('E') == error.offset;
      },
    );
    await assertHasFix(
      r'''
import 'lib.dart' show A, a, E;
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
class ImportLibraryShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_COMBINATOR;

  Future<void> test_extension_aliased_notShown_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  void m() {}
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' as lib show C;

void f(String s, lib.C c) {
  s.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib show C, E;

void f(String s, lib.C c) {
  s.m();
}
''');
  }

  Future<void> test_extension_notShown_getter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' show C;

void f(String s, C c) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show C, E;

void f(String s, C c) {
  s.m;
}
''');
  }

  Future<void> test_extension_notShown_method() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  void m() {}
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' show C;

void f(String s, C c) {
  s.m();
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show C, E;

void f(String s, C c) {
  s.m();
}
''');
  }

  Future<void> test_extension_notShown_operator() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  String operator -(String other) => this;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' show C;

void f(String s, C c) {
  s - '2';
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show C, E;

void f(String s, C c) {
  s - '2';
}
''');
  }

  Future<void> test_extension_notShown_setter() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  set m(int v) {}
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' show C;

void f(String s, C c) {
  s.m = 2;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' show C, E;

void f(String s, C c) {
  s.m = 2;
}
''');
  }

  Future<void> test_extension_shown_class_differentPrefix() async {
    newFile('$testPackageLibPath/lib.dart', '''
class C {}
extension E on String {
  int get m => 0;
}
''');
    await resolveTestCode('''
import 'package:test/lib.dart' as lib show C;
import 'package:test/lib.dart' show E;

void f(String s, lib2.C c) {
  s.m;
}
''');
    await assertHasFix('''
import 'package:test/lib.dart' as lib show C;
import 'package:test/lib.dart' show E, C;

void f(String s, C c) {
  s.m;
}
''');
  }

  Future<void> test_lint_active() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
''');
    await resolveTestCode(r'''
import 'lib.dart' show B, C;
void f(A a, C c) {
  print('$a $c');
}
''');
    await assertHasFix(r'''
import 'lib.dart' show A, B, C;
void f(A a, C c) {
  print('$a $c');
}
''');
  }

  // Two shows, and a hide that should be updated. Even though the hide is not
  // part of these tests, it should be fixed too for making the import correct.
  Future<void> test_multiple_combinators() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
class C {}
''');
    await resolveTestCode(r'''
// ignore: multiple_combinators
import 'lib.dart' show A show A, B hide B, C;
void f(A a, C c) {
  print('$a $c');
}
''');
    await assertHasFix(r'''
// ignore: multiple_combinators
import 'lib.dart' show A, C show A, B, C hide B;
void f(A a, C c) {
  print('$a $c');
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
import 'lib.dart' show A;
void f(A a) {
  print('$a ${E(3).m()}');
}
''');
    await assertHasFix(r'''
import 'lib.dart' show A, E;
void f(A a) {
  print('$a ${E(3).m()}');
}
''');
  }

  Future<void> test_package() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
class B {}
''');
    await resolveTestCode(r'''
import 'lib.dart' show A;
void f() {
  A? a;
  B b;
  print('$a $b');
}
''');
    await assertHasFix(r'''
import 'lib.dart' show A, B;
void f() {
  A? a;
  B b;
  print('$a $b');
}
''');
  }

  Future<void> test_sdk() async {
    await resolveTestCode(r'''
import 'dart:collection' show HashMap;
void f() {
  HashMap? s = null;
  LinkedHashMap? f = null;
  print('$s $f');
}
''');
    await assertHasFix(r'''
import 'dart:collection' show HashMap, LinkedHashMap;
void f() {
  HashMap? s = null;
  LinkedHashMap? f = null;
  print('$s $f');
}
''');
  }

  Future<void> test_static_samePackage() async {
    newFile('$testPackageLibPath/lib.dart', '''
class A {}
extension E on int {
  static String m() => '';
}
''');
    await resolveTestCode(r'''
import 'lib.dart' show A;
void f(A a) {
  print('$a ${E.m()}');
}
''');
    await assertHasFix(r'''
import 'lib.dart' show A, E;
void f(A a) {
  print('$a ${E.m()}');
}
''');
  }
}
