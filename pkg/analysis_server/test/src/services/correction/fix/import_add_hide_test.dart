// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportAddHideTest);
  });
}

@reflectiveTest
class ImportAddHideTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_HIDE;

  Future<void> test_doubleAliasedImports() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' as i;
import 'lib2.dart' as i;

void f(i.N? n) {
  print(n);
}
''');
    await assertHasFixesWithoutApplying(
        expectedNumberOfFixesForKind: 2,
        matchFixMessages: [
          "Add 'hide N' to library 'lib1.dart' as 'i' import",
          "Add 'hide N' to library 'lib2.dart' as 'i' import",
        ]);
    await assertHasFix('''
import 'lib1.dart' as i hide N;
import 'lib2.dart' as i;

void f(i.N? n) {
  print(n);
}
''', matchFixMessage: "Add 'hide N' to library 'lib1.dart' as 'i' import");
    await assertHasFix('''
import 'lib1.dart' as i;
import 'lib2.dart' as i hide N;

void f(i.N? n) {
  print(n);
}
''', matchFixMessage: "Add 'hide N' to library 'lib2.dart' as 'i' import");
  }

  Future<void> test_DoubleImports() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
class N {}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''');
    await assertHasFixesWithoutApplying(
        expectedNumberOfFixesForKind: 2,
        matchFixMessages: [
          "Add 'hide N' to library 'lib1.dart' import",
          "Add 'hide N' to library 'lib2.dart' import",
        ]);
    await assertHasFix('''
import 'lib1.dart' hide N;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Add 'hide N' to library 'lib1.dart' import");
    await assertHasFix('''
import 'lib1.dart';
import 'lib2.dart' hide N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Add 'hide N' to library 'lib2.dart' import");
  }

  Future<void> test_doubleImports_bothShow() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' show N;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''');
    await assertNoFix();
  }

  Future<void> test_doubleImports_constant() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
const foo = 0;''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
const foo = 0;''');
    await resolveTestCode('''
import 'lib1.dart' show foo;
import 'lib2.dart';

void f() {
  print(foo);
}
''');
    await assertHasFix('''
import 'lib1.dart' show foo;
import 'lib2.dart' hide foo;

void f() {
  print(foo);
}
''', matchFixMessage: "Add 'hide foo' to library 'lib2.dart' import");
  }

  Future<void> test_doubleImports_exportedByImport() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
export 'lib3.dart';''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
mixin M {}''');
    newFile('$testPackageLibPath/lib3.dart', '''
library lib3;
mixin M {}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart' show M;

class C with M {}
''');
    await assertHasFix('''
import 'lib1.dart' hide M;
import 'lib2.dart' show M;

class C with M {}
''', matchFixMessage: "Add 'hide M' to library 'lib1.dart' import",
        errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_doubleImports_extension() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
extension E on int {
  bool get isDivisibleByThree => this % 3 == 0;
}''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
extension E on int {
  bool get isDivisibleByThree => this % 3 == 0;
}''');
    await resolveTestCode('''
import 'lib1.dart' show E;
import 'lib2.dart';

void foo(int i) {
  print(E(i.isDivisibleByThree));
}
''');
    await assertHasFix('''
import 'lib1.dart' show E;
import 'lib2.dart' hide E;

void foo(int i) {
  print(E(i.isDivisibleByThree));
}
''', matchFixMessage: "Add 'hide E' to library 'lib2.dart' import",
        errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_doubleImports_function() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
void bar() {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
void bar() {}''');
    await resolveTestCode('''
import 'lib1.dart' show bar;
import 'lib2.dart';

void foo() {
  bar();
}
''');
    await assertHasFix('''
import 'lib1.dart' show bar;
import 'lib2.dart' hide bar;

void foo() {
  bar();
}
''', matchFixMessage: "Add 'hide bar' to library 'lib2.dart' import");
  }

  Future<void> test_doubleImports_mixin() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
mixin M {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
mixin M {}''');
    await resolveTestCode('''
import 'lib1.dart' show M;
import 'lib2.dart';

class C with M {}
''');
    await assertHasFix('''
import 'lib1.dart' show M;
import 'lib2.dart' hide M;

class C with M {}
''', matchFixMessage: "Add 'hide M' to library 'lib2.dart' import",
        errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_doubleImports_oneHide() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class M {} class N {} class O {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' hide M, O;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''');
    await assertHasFix('''
import 'lib1.dart' hide M, N, O;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Add 'hide N' to library 'lib1.dart' import");
  }

  Future<void> test_doubleImports_oneShow() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' show N;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''');
    await assertHasFix('''
import 'lib1.dart' show N;
import 'lib2.dart' hide N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Add 'hide N' to library 'lib2.dart' import");
  }

  Future<void> test_doubleImports_variable() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
var foo = 0;''');
    newFile('$testPackageLibPath/lib2.dart', '''
library lib2;
var foo = 0;''');
    await resolveTestCode('''
import 'lib1.dart' show foo;
import 'lib2.dart';

void f() {
  print(foo);
}
''');
    await assertHasFix('''
import 'lib1.dart' show foo;
import 'lib2.dart' hide foo;

void f() {
  print(foo);
}
''', matchFixMessage: "Add 'hide foo' to library 'lib2.dart' import");
  }
}
