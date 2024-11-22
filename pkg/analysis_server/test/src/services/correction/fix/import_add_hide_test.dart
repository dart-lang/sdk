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
    defineReflectiveTests(ImportRemoveShowTest);
  });
}

@reflectiveTest
class ImportAddHideTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_HIDE;

  Future<void> test_double() async {
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
          "Hide others to use 'N' from 'lib1.dart'",
          "Hide others to use 'N' from 'lib2.dart'",
        ]);
    await assertHasFix('''
import 'lib1.dart' hide N;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Hide others to use 'N' from 'lib2.dart'");
    await assertHasFix('''
import 'lib1.dart';
import 'lib2.dart' hide N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Hide others to use 'N' from 'lib1.dart'");
  }

  Future<void> test_double_aliased() async {
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
          "Hide others to use 'N' from 'lib1.dart' as i",
          "Hide others to use 'N' from 'lib2.dart' as i",
        ]);
    await assertHasFix('''
import 'lib1.dart' as i;
import 'lib2.dart' as i hide N;

void f(i.N? n) {
  print(n);
}
''', matchFixMessage: "Hide others to use 'N' from 'lib1.dart' as i");
    await assertHasFix('''
import 'lib1.dart' as i hide N;
import 'lib2.dart' as i;

void f(i.N? n) {
  print(n);
}
''', matchFixMessage: "Hide others to use 'N' from 'lib2.dart' as i");
  }

  Future<void> test_double_constant() async {
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
''', matchFixMessage: "Hide others to use 'foo' from 'lib1.dart'");
  }

  Future<void> test_double_exportedByImport() async {
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
''', matchFixMessage: "Hide others to use 'M' from 'lib2.dart'",
        errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_double_extension() async {
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
''', matchFixMessage: "Hide others to use 'E' from 'lib1.dart'",
        errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_double_function() async {
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
''', matchFixMessage: "Hide others to use 'bar' from 'lib1.dart'");
  }

  Future<void> test_double_mixin() async {
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
''', matchFixMessage: "Hide others to use 'M' from 'lib1.dart'",
        errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_double_oneHide() async {
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
''', matchFixMessage: "Hide others to use 'N' from 'lib2.dart'");
  }

  Future<void> test_double_oneShow() async {
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
''', matchFixMessage: "Hide others to use 'N' from 'lib1.dart'");
  }

  Future<void> test_double_variable() async {
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
''', matchFixMessage: "Hide others to use 'foo' from 'lib1.dart'");
  }

  @FailingTest(reason: 'No error produced')
  Future<void> test_multiLevelParts() async {
    // Create a tree of files that all import 'dart:math' and ensure we find
    // only the import from the parent (not a grandparent, sibling, or child).
    //
    // - lib                       declares Random
    //
    // - root                      has import
    //     - level1_other          has import
    //     - level1                has imports, is the used reference
    //         - level2_other      has import
    //         - test              has reference <-- testing this
    //             - level3_other  has import

    newFile('$testPackageLibPath/lib.dart', '''
class Random {}
''');

    newFile('$testPackageLibPath/root.dart', '''
import 'dart:math';
part 'level1_other.dart';
part 'level1.dart';
''');

    newFile('$testPackageLibPath/level1_other.dart', '''
part of 'root.dart';
import 'dart:math';
''');

    newFile('$testPackageLibPath/level1.dart', '''
part of 'root.dart';
import 'dart:math';
import 'lib.dart';
part 'level2_other.dart';
part 'test.dart';
''');

    newFile('$testPackageLibPath/level2_other.dart', '''
part of 'level1.dart';
import 'dart:math';
''');

    newFile('$testPackageLibPath/level3_other.dart', '''
part of 'test.dart';
import 'dart:math';
''');

    await resolveTestCode('''
part of 'level1.dart';
part 'level3_other.dart';

Random? r;
''');

    await assertHasFix(
      '''
part of 'root.dart';
import 'dart:math';
import 'lib.dart';
part 'level2_other.dart';
part 'test.dart';
''',
      target: 'lib.dart',
    );
  }

  Future<void> test_part() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
class N {}''');
    newFile('$testPackageLibPath/other.dart', '''
import 'lib1.dart';
import 'lib2.dart';
part 'test.dart';
''');
    await resolveTestCode('''
part of 'other.dart';
import 'lib1.dart';
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''');
    await assertHasFixesWithoutApplying(
      expectedNumberOfFixesForKind: 2,
      matchFixMessages: [
        "Hide others to use 'N' from 'lib1.dart'",
        "Hide others to use 'N' from 'lib2.dart'",
      ],
    );
    await assertHasFix(
      '''
part of 'other.dart';
import 'lib1.dart' hide N;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''',
      matchFixMessage: "Hide others to use 'N' from 'lib2.dart'",
    );
    await assertHasFix(
      '''
part of 'other.dart';
import 'lib1.dart';
import 'lib2.dart' hide N;

void f(N? n) {
  print(n);
}
''',
      matchFixMessage: "Hide others to use 'N' from 'lib1.dart'",
    );
  }

  Future<void> test_show_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class N {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' as l show N;
import 'lib2.dart' as l;

void f(l.N? n) {
  print(n);
}
''');
    await assertHasFix('''
import 'lib1.dart' as l show N;
import 'lib2.dart' as l hide N;

void f(l.N? n) {
  print(n);
}
''', matchFixMessage: "Hide others to use 'N' from 'lib1.dart' as l");
  }

  Future<void> test_triple() async {
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
''', matchFixMessage: "Hide others to use 'M' from 'lib1.dart'",
        errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
    await assertHasFix('''
import 'lib1.dart' hide M;
import 'lib2.dart';
import 'lib3.dart' hide M;

class C with M {}
''', matchFixMessage: "Hide others to use 'M' from 'lib2.dart'",
        errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
    await assertHasFix('''
import 'lib1.dart' hide M;
import 'lib2.dart' hide M;
import 'lib3.dart';

class C with M {}
''', matchFixMessage: "Hide others to use 'M' from 'lib3.dart'",
        errorFilter: (error) {
      return error.errorCode == CompileTimeErrorCode.AMBIGUOUS_IMPORT;
    });
  }

  Future<void> test_triple_oneAliased() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const foo = 0;''');
    newFile('$testPackageLibPath/lib2.dart', '''
const foo = 0;''');
    await resolveTestCode('''
import 'lib1.dart' as lib;
import 'lib1.dart';
import 'lib2.dart';

void f() {
  print(foo);
}
''');
    await assertHasFix('''
import 'lib1.dart' as lib;
import 'lib1.dart';
import 'lib2.dart' hide foo;

void f() {
  print(foo);
}
''', matchFixMessage: "Hide others to use 'foo' from 'lib1.dart'");
  }

  Future<void> test_triple_twoAliased() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const foo = 0;''');
    newFile('$testPackageLibPath/lib2.dart', '''
const foo = 0;''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib1.dart' as lib;
import 'lib2.dart' as lib;

void f() {
  print(lib.foo);
}
''');
    await assertHasFix('''
import 'lib1.dart';
import 'lib1.dart' as lib;
import 'lib2.dart' as lib hide foo;

void f() {
  print(lib.foo);
}
''', matchFixMessage: "Hide others to use 'foo' from 'lib1.dart' as lib");
  }
}

@reflectiveTest
class ImportRemoveShowTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.IMPORT_LIBRARY_REMOVE_SHOW;

  Future<void> test_double() async {
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
    await assertHasFix('''
import 'lib1.dart' hide N;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Remove show to use 'N' from 'lib2.dart'");
  }

  Future<void> test_double_aliased() async {
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
          "Remove show to use 'N' from 'lib1.dart' as l",
          "Remove show to use 'N' from 'lib2.dart' as l",
        ]);
    await assertHasFix('''
import 'lib1.dart' as l hide N;
import 'lib2.dart' as l show N;

void f(l.N? n) {
  print(n);
}
''', matchFixMessage: "Remove show to use 'N' from 'lib2.dart' as l");
    await assertHasFix('''
import 'lib1.dart' as l show N;
import 'lib2.dart' as l hide N;

void f(l.N? n) {
  print(n);
}
''', matchFixMessage: "Remove show to use 'N' from 'lib1.dart' as l");
  }

  Future<void> test_double_oneHide() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const foo = 0;''');
    newFile('$testPackageLibPath/lib2.dart', '''
const foo = 0;''');
    await resolveTestCode('''
import 'lib1.dart' hide foo;
import 'lib2.dart' show foo;

void f() {
  print(foo);
}
''');
    await assertNoFix();
  }

  Future<void> test_moreShow() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class N {}
class M {}''');
    newFile('$testPackageLibPath/lib2.dart', '''
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' show N, M;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''');
    await assertHasFixesWithoutApplying(
        expectedNumberOfFixesForKind: 1,
        matchFixMessages: [
          "Remove show to use 'N' from 'lib2.dart'",
        ]);
    await assertHasFix('''
import 'lib1.dart' show M;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Remove show to use 'N' from 'lib2.dart'");
  }

  Future<void> test_one_show() async {
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
import 'lib1.dart' hide foo;
import 'lib2.dart';

void f() {
  print(foo);
}
''', matchFixMessage: "Remove show to use 'foo' from 'lib2.dart'");
  }

  Future<void> test_triple_twoAliased() async {
    newFile('$testPackageLibPath/lib1.dart', '''
const foo = 0;''');
    newFile('$testPackageLibPath/lib2.dart', '''
const foo = 0;''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib1.dart' as lib show foo;
import 'lib2.dart' as lib;

void f() {
  print(lib.foo);
}
''');
    await assertHasFix('''
import 'lib1.dart';
import 'lib1.dart' as lib hide foo;
import 'lib2.dart' as lib;

void f() {
  print(lib.foo);
}
''', matchFixMessage: "Remove show to use 'foo' from 'lib2.dart' as lib");
  }
}
