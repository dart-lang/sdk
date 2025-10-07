// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
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
    defineReflectiveTests(ImportAddHideTest);
    defineReflectiveTests(ImportRemoveShowTest);
  });
}

@reflectiveTest
class ImportAddHideTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.importLibraryHide;

  Future<void> test_double() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
      ],
    );
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
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
      ],
    );
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
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
const foo = 0;''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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

  Future<void> test_double_doubleExportedByImport() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
mixin M {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
mixin M {}''');
    newFile(join(testPackageLibPath, 'lib3.dart'), '''
export 'lib2.dart';''');
    newFile(join(testPackageLibPath, 'lib4.dart'), '''
export 'lib3.dart';''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib4.dart';

class C with M {}
''');
    await assertHasFix(
      '''
import 'lib1.dart' hide M;
import 'lib4.dart';

class C with M {}
''',
      matchFixMessage: "Hide others to use 'M' from 'lib4.dart'",
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.ambiguousImport;
      },
    );
  }

  Future<void> test_double_equal_importUris() async {
    // https://github.com/dart-lang/sdk/issues/56830#issuecomment-2573945155
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
var foo = 0;
var bar = 0;
var baz = 0;
''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
var foo = 0;''');
    await resolveTestCode('''
import 'lib1.dart' hide bar;
import 'lib1.dart' hide baz;
import 'lib2.dart';

void f() {
  print(bar);
  print(baz);
  print(foo);
}
''');
    await assertNoFix();
  }

  Future<void> test_double_exportedByImport() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
mixin M {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
mixin M {}''');
    newFile(join(testPackageLibPath, 'lib3.dart'), '''
export 'lib2.dart';''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib3.dart';

class C with M {}
''');
    await assertHasFix(
      '''
import 'lib1.dart' hide M;
import 'lib3.dart';

class C with M {}
''',
      matchFixMessage: "Hide others to use 'M' from 'lib3.dart'",
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.ambiguousImport;
      },
    );
  }

  Future<void> test_double_extension() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
extension E on int {
  bool get isDivisibleByThree => this % 3 == 0;
}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
    await assertHasFix(
      '''
import 'lib1.dart';
import 'lib2.dart' hide E;

void foo(int i) {
  print(E(i.isDivisibleByThree));
}
''',
      matchFixMessage: "Hide others to use 'E' from 'lib1.dart'",
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.ambiguousImport;
      },
    );
  }

  Future<void> test_double_function() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
void bar() {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
mixin M {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
mixin M {}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';

class C with M {}
''');
    await assertHasFix(
      '''
import 'lib1.dart';
import 'lib2.dart' hide M;

class C with M {}
''',
      matchFixMessage: "Hide others to use 'M' from 'lib1.dart'",
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.ambiguousImport;
      },
    );
  }

  Future<void> test_double_oneHide() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class M {} class N {} class O {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' hide M, O;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''');
    await assertHasFix('''
import 'lib1.dart' hide M, O, N;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Hide others to use 'N' from 'lib2.dart'");
  }

  Future<void> test_double_oneHide_sort() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class M {} class N {} class O {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
var foo = 0;''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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

  Future<void> test_multiLevelParts() async {
    // Create a tree of files that all import 'dart:math' and ensure we find
    // only the import from the parent (not a grandparent, sibling, or child).
    //
    // - lib1                      declares A
    // - lib2                      declares A
    //
    // - root                      has import
    //     - level1_other          has import
    //     - level1                has imports, is the used reference
    //         - level2_other      has import
    //         - test              has reference <-- testing this
    //             - level3_other  has import

    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class A {}
''');

    newFile(join(testPackageLibPath, 'lib2.dart'), '''
class A {}
''');

    newFile(join(testPackageLibPath, 'root.dart'), '''
import 'lib1.dart';
part 'level1_other.dart';
part 'level1.dart';
''');

    newFile(join(testPackageLibPath, 'level1_other.dart'), '''
part of 'root.dart';
import 'lib1.dart';
''');

    newFile(join(testPackageLibPath, 'level1.dart'), '''
part of 'root.dart';
import 'lib1.dart';
import 'lib2.dart';
part 'level2_other.dart';
part 'test.dart';
''');

    newFile(join(testPackageLibPath, 'level2_other.dart'), '''
part of 'level1.dart';
import 'lib1.dart';
''');

    newFile(join(testPackageLibPath, 'level3_other.dart'), '''
part of 'test.dart';
import 'lib1.dart';
''');

    await resolveTestCode('''
part of 'level1.dart';
part 'level3_other.dart';

A? a;
''');

    await assertHasFix(
      '''
part of 'root.dart';
import 'lib1.dart' hide A;
import 'lib2.dart';
part 'level2_other.dart';
part 'test.dart';
''',
      target: join(testPackageLibPath, 'level1.dart'),
      matchFixMessage: "Hide others to use 'A' from 'lib2.dart'",
    );
  }

  Future<void> test_multipleCombinators() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
void bar() {}
void baz() {}
void foo() {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
void bar() {}''');
    await resolveTestCode('''
// ignore: multiple_combinators
import 'lib1.dart' hide baz hide foo;
import 'lib2.dart';

void foo() {
  bar();
}
''');
    await assertHasFix('''
// ignore: multiple_combinators
import 'lib1.dart' hide baz, bar hide foo, bar;
import 'lib2.dart';

void foo() {
  bar();
}
''', matchFixMessage: "Hide others to use 'bar' from 'lib2.dart'");
  }

  Future<void> test_part() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'other.dart'), '''
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
    await assertHasFix('''
part of 'other.dart';
import 'lib1.dart' hide N;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Hide others to use 'N' from 'lib2.dart'");
    await assertHasFix('''
part of 'other.dart';
import 'lib1.dart';
import 'lib2.dart' hide N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Hide others to use 'N' from 'lib1.dart'");
  }

  Future<void> test_show_prefixed() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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

  Future<void> test_static_member() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
class N {}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';

void f() {
  var _ = [N.new];
}
''');
    await assertHasFix(
      '''
import 'lib1.dart' hide N;
import 'lib2.dart';

void f() {
  var _ = [N.new];
}
''',
      matchFixMessage: "Hide others to use 'N' from 'lib2.dart'",
      errorFilter: (error) =>
          error.diagnosticCode == CompileTimeErrorCode.ambiguousImport,
    );
  }

  Future<void> test_static_member_prefixed() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' as l;
import 'lib2.dart' as l;

void f() {
  var _ = [l.N.new];
}
''');
    await assertHasFix(
      '''
import 'lib1.dart' as l hide N;
import 'lib2.dart' as l;

void f() {
  var _ = [l.N.new];
}
''',
      matchFixMessage: "Hide others to use 'N' from 'lib2.dart' as l",
      errorFilter: (error) =>
          error.diagnosticCode == CompileTimeErrorCode.ambiguousImport,
    );
  }

  Future<void> test_triple() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
export 'lib3.dart';''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
mixin M {}''');
    newFile(join(testPackageLibPath, 'lib3.dart'), '''
mixin M {}''');
    await resolveTestCode('''
import 'lib1.dart';
import 'lib2.dart';
import 'lib3.dart';

class C with M {}
''');
    await assertHasFix(
      '''
import 'lib1.dart';
import 'lib2.dart' hide M;
import 'lib3.dart' hide M;

class C with M {}
''',
      matchFixMessage: "Hide others to use 'M' from 'lib1.dart'",
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.ambiguousImport;
      },
    );
    await assertHasFix(
      '''
import 'lib1.dart' hide M;
import 'lib2.dart';
import 'lib3.dart' hide M;

class C with M {}
''',
      matchFixMessage: "Hide others to use 'M' from 'lib2.dart'",
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.ambiguousImport;
      },
    );
    await assertHasFix(
      '''
import 'lib1.dart' hide M;
import 'lib2.dart' hide M;
import 'lib3.dart';

class C with M {}
''',
      matchFixMessage: "Hide others to use 'M' from 'lib3.dart'",
      errorFilter: (error) {
        return error.diagnosticCode == CompileTimeErrorCode.ambiguousImport;
      },
    );
  }

  Future<void> test_triple_oneAliased() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
const foo = 0;''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
const foo = 0;''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
  FixKind get kind => DartFixKind.importLibraryRemoveShow;

  Future<void> test_double() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
      ],
    );
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

  Future<void> test_double_equal_importUris() async {
    // https://github.com/dart-lang/sdk/issues/56830#issuecomment-2573945155
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
var foo = 0;
var bar = 0;
var baz = 0;
''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
var foo = 0;''');
    await resolveTestCode('''
import 'lib1.dart' show bar, foo;
import 'lib1.dart' show baz, foo;
import 'lib2.dart';

void f() {
  print(bar);
  print(baz);
  print(foo);
}
''');
    await assertNoFix();
  }

  Future<void> test_double_oneHide() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
const foo = 0;''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}
class M {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
      matchFixMessages: ["Remove show to use 'N' from 'lib2.dart'"],
    );
    await assertHasFix('''
import 'lib1.dart' show M;
import 'lib2.dart';

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Remove show to use 'N' from 'lib2.dart'");
  }

  Future<void> test_moreShow_sort() async {
    createAnalysisOptionsFile(lints: [LintNames.combinators_ordering]);
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}
class M {}
class O {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
class N {}''');
    await resolveTestCode('''
import 'lib1.dart' show N, O, M;
import 'lib2.dart';

void f(N? n, O? o) {
  print(n);
}
''');
    await assertHasFix(
      '''
import 'lib1.dart' show M, O;
import 'lib2.dart';

void f(N? n, O? o) {
  print(n);
}
''',
      errorFilter: (error) =>
          error.diagnosticCode == CompileTimeErrorCode.ambiguousImport,
      matchFixMessage: "Remove show to use 'N' from 'lib2.dart'",
    );
  }

  Future<void> test_multipleCombinators1() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class M {}
class N {}
class O {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
class N {}''');
    await resolveTestCode('''
// ignore: multiple_combinators
import 'lib1.dart' show N show N, O, M;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''');
    await assertHasFix('''
// ignore: multiple_combinators
import 'lib1.dart' show O, M;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Remove show to use 'N' from 'lib2.dart'");
  }

  Future<void> test_multipleCombinators2() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
class N {}''');
    await resolveTestCode('''
// ignore: multiple_combinators
import 'lib1.dart' show N show N;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''');
    await assertHasFix('''
// ignore: multiple_combinators
import 'lib1.dart' hide N;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Remove show to use 'N' from 'lib2.dart'");
  }

  Future<void> test_multipleCombinators3() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
class M {}
class N {}''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
class N {}''');
    await resolveTestCode('''
// ignore: multiple_combinators
import 'lib1.dart' show N hide M hide M;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''');
    await assertHasFix('''
// ignore: multiple_combinators
import 'lib1.dart' hide M, N hide M, N;
import 'lib2.dart' show N;

void f(N? n) {
  print(n);
}
''', matchFixMessage: "Remove show to use 'N' from 'lib2.dart'");
  }

  Future<void> test_one_show() async {
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
var foo = 0;''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
    newFile(join(testPackageLibPath, 'lib1.dart'), '''
const foo = 0;''');
    newFile(join(testPackageLibPath, 'lib2.dart'), '''
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
