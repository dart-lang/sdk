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
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
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
          "Use 'N' from 'lib1.dart' as i",
          "Use 'N' from 'lib2.dart' as i",
        ]);
    await assertHasFix('''
import 'lib1.dart' as i;
import 'lib2.dart' as i hide N;

void f(i.N? n) {
  print(n);
}
''', matchFixMessage: "Use 'N' from 'lib1.dart' as i");
    await assertHasFix('''
import 'lib1.dart' as i hide N;
import 'lib2.dart' as i;

void f(i.N? n) {
  print(n);
}
''', matchFixMessage: "Use 'N' from 'lib2.dart' as i");
  }

  Future<void> test_DoubleImports() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
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
          "Use 'N' from 'lib1.dart'",
          "Use 'N' from 'lib2.dart'",
        ]);
    await assertHasFix('''
import 'lib1.dart' hide N;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Use 'N' from 'lib2.dart'");
    await assertHasFix('''
import 'lib1.dart';
import 'lib2.dart' hide N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Use 'N' from 'lib1.dart'");
  }

  Future<void> test_doubleImports_bothShow() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' show N;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''');
    await assertHasFixesWithoutApplying(
        expectedNumberOfFixesForKind: 2,
        matchFixMessages: [
          "Use 'N' from 'lib1.dart' (removing 'show')",
          "Use 'N' from 'lib2.dart' (removing 'show')",
        ]);
    await assertHasFix('''
import 'lib1.dart' hide N;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Use 'N' from 'lib2.dart' (removing 'show')");
    await assertHasFix('''
import 'lib1.dart' show N;
import 'lib2.dart' hide N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Use 'N' from 'lib1.dart' (removing 'show')");
  }

  Future<void> test_doubleImports_constant() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const foo = 0;''');
    newFile('$testPackageLibPath/lib2.dart', '''
const foo = 0;''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';

void f() {
  print(foo);
}
''');
    await assertHasFix('''
import 'lib1.dart';
import 'lib2.dart' hide foo;

void f() {
  print(foo);
}
''', matchFixMessage: "Use 'foo' from 'lib1.dart'");
  }

  Future<void> test_doubleImports_exportedByImport() async {
    newFile('$testPackageLibPath/lib1.dart', '''
export 'lib3.dart';''');
    newFile('$testPackageLibPath/lib2.dart', '''
mixin M {}''');
    newFile('$testPackageLibPath/lib3.dart', '''
mixin M {}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';

class C with M {}
''');
    await assertHasFix('''
import 'lib1.dart' hide M;
import 'lib2.dart';

class C with M {}
''', matchFixMessage: "Use 'M' from 'lib2.dart'", errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_doubleImports_extension() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension E on int {
  bool get isDivisibleByThree => this % 3 == 0;
}''');
    newFile('$testPackageLibPath/lib2.dart', '''
extension E on int {
  bool get isDivisibleByThree => this % 3 == 0;
}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';

void foo(int i) {
  print(E(i.isDivisibleByThree));
}
''');
    await assertHasFix('''
import 'lib1.dart';
import 'lib2.dart' hide E;

void foo(int i) {
  print(E(i.isDivisibleByThree));
}
''', matchFixMessage: "Use 'E' from 'lib1.dart'", errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_doubleImports_function() async {
    newFile('$testPackageLibPath/lib1.dart', '''
void bar() {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
void bar() {}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';

void foo() {
  bar();
}
''');
    await assertHasFix('''
import 'lib1.dart';
import 'lib2.dart' hide bar;

void foo() {
  bar();
}
''', matchFixMessage: "Use 'bar' from 'lib1.dart'");
  }

  Future<void> test_doubleImports_mixin() async {
    newFile('$testPackageLibPath/lib1.dart', '''
mixin M {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
mixin M {}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';

class C with M {}
''');
    await assertHasFix('''
import 'lib1.dart';
import 'lib2.dart' hide M;

class C with M {}
''', matchFixMessage: "Use 'M' from 'lib1.dart'", errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_doubleImports_oneHide() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class M {} class N {} class O {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' hide M, O;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''');
    await assertHasFix('''
import 'lib1.dart' hide M, N, O;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Use 'N' from 'lib2.dart'");
  }

  Future<void> test_doubleImports_oneShow() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
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
''', matchFixMessage: "Use 'N' from 'lib1.dart'");
  }

  Future<void> test_doubleImports_variable() async {
    newFile('$testPackageLibPath/lib1.dart', '''
var foo = 0;''');
    newFile('$testPackageLibPath/lib2.dart', '''
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
''', matchFixMessage: "Use 'foo' from 'lib1.dart'");
  }

  Future<void> test_show_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' as l show N;
import 'lib2.dart' as l show N;

void f(l.N? n) {
  print(n);
}
''');
    await assertHasFixesWithoutApplying(
        expectedNumberOfFixesForKind: 2,
        matchFixMessages: [
          "Use 'N' from 'lib1.dart' as l (removing 'show')",
          "Use 'N' from 'lib2.dart' as l (removing 'show')",
        ]);
    await assertHasFix('''
import 'lib1.dart' as l hide N;
import 'lib2.dart' as l show N;

void f(l.N? n) {
  print(n);
}
''', matchFixMessage: "Use 'N' from 'lib2.dart' as l (removing 'show')");
    await assertHasFix('''
import 'lib1.dart' as l show N;
import 'lib2.dart' as l hide N;

void f(l.N? n) {
  print(n);
}
''', matchFixMessage: "Use 'N' from 'lib1.dart' as l (removing 'show')");
  }

  Future<void> test_tripleImports() async {
    newFile('$testPackageLibPath/lib1.dart', '''
export 'lib3.dart';''');
    newFile('$testPackageLibPath/lib2.dart', '''
mixin M {}''');
    newFile('$testPackageLibPath/lib3.dart', '''
mixin M {}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';
import 'lib3.dart';

class C with M {}
''');
    await assertHasFix('''
import 'lib1.dart';
import 'lib2.dart' hide M;
import 'lib3.dart' hide M;

class C with M {}
''', matchFixMessage: "Use 'M' from 'lib1.dart'", errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
    await assertHasFix('''
import 'lib1.dart' hide M;
import 'lib2.dart';
import 'lib3.dart' hide M;

class C with M {}
''', matchFixMessage: "Use 'M' from 'lib2.dart'", errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
    await assertHasFix('''
import 'lib1.dart' hide M;
import 'lib2.dart' hide M;
import 'lib3.dart';

class C with M {}
''', matchFixMessage: "Use 'M' from 'lib3.dart'", errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }
}
