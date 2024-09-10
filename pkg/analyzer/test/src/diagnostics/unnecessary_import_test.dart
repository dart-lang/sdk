// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnnecessaryImportTest);
  });
}

@reflectiveTest
class UnnecessaryImportTest extends PubPackageResolutionTest {
  test_library_annotationOnDirective() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {
  const A() {}
}
''');
    await assertNoErrorsInCode(r'''
@A()
import 'lib1.dart';
''');
  }

  test_library_as() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'lib1.dart';
class B {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart' as two;
f(A a, two.B b) {}
''');
  }

  test_library_as_differentPrefixes() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'lib1.dart';
class B {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' as one;
import 'lib2.dart' as two;
f(one.A a, two.B b) {}
''');
  }

  test_library_as_equalPrefixes_referenced() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one;
f(one.A a, one.B b) {}
''');
  }

  test_library_as_equalPrefixes_referenced_via_export() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class B {}
''');
    newFile('$testPackageLibPath/lib3.dart', r'''
export 'lib2.dart';
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib3.dart' as one;
f(one.A a, one.B b) {}
''');
  }

  test_library_as_equalPrefixes_unreferenced() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', r'''
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one; // ignore: unused_import
f(one.A a) {}
''');
  }

  test_library_as_show_multipleElements() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class A {}
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one show A, B;
f(one.A a, one.B b) {}
''');
  }

  test_library_as_showTopLevelFunction() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class One {}
topLevelFunction() {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
f(One o) {
  one.topLevelFunction();
}
''');
  }

  test_library_as_showTopLevelFunction_multipleDirectives() async {
    newFile('$testPackageLibPath/lib1.dart', r'''
class One {}
topLevelFunction() {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
import 'lib1.dart' as two show topLevelFunction;
f(One o) {
  one.topLevelFunction();
  two.topLevelFunction();
}
''');
  }

  test_library_as_systemShadowing() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class File {}
''');
    await assertNoErrorsInCode('''
import 'dart:io' as io;
import 'lib1.dart' as io;
g(io.Directory d, io.File f) {}
''');
  }

  test_library_as_unnecessary() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'lib1.dart';
class B {}
''');
    await assertErrorsInCode('''
import 'lib1.dart' as p;
import 'lib2.dart' as p;
f(p.A a, p.B b) {}
''', [
      error(HintCode.UNNECESSARY_IMPORT, 7, 11),
    ]);
  }

  test_library_duplicateImport_differentPrefix() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
class B {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';
import 'lib1.dart' as p;
f(A a1, p.A a2, B b) {}
''');
  }

  test_library_extension_equalPrefixes_unnecessary() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension E1 on int {
  void foo() {}
}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'lib1.dart';
extension E2 on int {
  void bar() {}
}
''');
    await assertErrorsInCode('''
import 'lib1.dart' as prefix;
import 'lib2.dart' as prefix;
void f() {
  0.foo();
  0.bar();
}
''', [
      error(HintCode.UNNECESSARY_IMPORT, 7, 11),
    ]);
  }

  test_library_extension_noPrefixes_necessary() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension E1 on int {
  void foo() {}
}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
extension E2 on int {
  void bar() {}
}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
void f() {
  0.foo();
  0.bar();
}
''');
  }

  test_library_extension_noPrefixes_unnecessary() async {
    newFile('$testPackageLibPath/lib1.dart', '''
extension E1 on int {
  void foo() {}
}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'lib1.dart';
extension E2 on int {
  void bar() {}
}
''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
void f() {
  0.foo();
  0.bar();
}
''', [
      error(HintCode.UNNECESSARY_IMPORT, 7, 11),
    ]);
  }

  test_library_hasDeprecatedExport_hasNotDeprecatedImport_hasOtherClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
library;

@deprecated
export 'a.dart';

class B {}
''');

    // `import b` is not reported because provides used `B`.
    // `A` is from both `a.dart` and `b.dart`, so not reported.
    await assertNoErrorsInCode('''
import 'a.dart';
import 'b.dart';

void f(A _, B _) {}
''');
  }

  test_library_hasDeprecatedExport_hasNotDeprecatedImport_noOtherClass() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    newFile('$testPackageLibPath/c.dart', r'''
library;

@deprecated
export 'b.dart';

class C {}
''');

    // `import c` is unnecessary because we use only `B` from it.
    // But the export of `B` from `c.dart` is deprecated.
    // We can get `B` from `import b`, in a not deprecated way.
    // It also declares `C`, but we don't use it.
    await assertErrorsInCode('''
import 'a.dart';
import 'b.dart';
import 'c.dart';

void f(A _, B _) {}
''', [
      error(HintCode.UNNECESSARY_IMPORT, 41, 8),
    ]);
  }

  test_library_hasDeprecatedExport_noNotDeprecatedImport() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', r'''
class B {}
''');

    newFile('$testPackageLibPath/c.dart', r'''
library;

@deprecated
export 'b.dart';
''');

    // `import c` is not marked as unnecessary because of there is
    // `DEPRECATED_EXPORT_USE` already reported.
    await assertErrorsInCode('''
import 'a.dart';
import 'c.dart';

void f(A _, B _) {}
''', [
      error(WarningCode.DEPRECATED_EXPORT_USE, 47, 1),
    ]);
  }

  test_library_hide() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'lib1.dart' hide A;
class B {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
f(A a, B b) {}
''');
  }

  test_library_systemShadowing() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class File {}
''');
    await assertNoErrorsInCode('''
import 'dart:io';
import 'lib1.dart';
g(Directory d, File f) {}
''');
  }

  test_library_unnecessary_hasError() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
''');

    newFile('$testPackageLibPath/b.dart', '''
export 'a.dart';
class B {}
''');

    await assertErrorsInCode('''
import 'a.dart';
import 'b.dart';
void f(A _, B _, C _) {}
''', [
      error(CompileTimeErrorCode.UNDEFINED_CLASS, 51, 1),
    ]);
  }

  test_library_unnecessaryImport() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'lib1.dart';
class B {}
''');
    await assertErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
f(A a, B b) {}
''', [
      error(HintCode.UNNECESSARY_IMPORT, 7, 11),
    ]);
  }

  test_library_unnecessaryImport_sameUri() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', '''
export 'lib1.dart';
class B {}
''');
    await assertErrorsInCode('''
import 'dart:async';
import 'dart:async' show Completer;
f(FutureOr<int> a, Completer<int> b) {}
''', [
      error(HintCode.UNNECESSARY_IMPORT, 28, 12),
    ]);
  }

  test_library_uriDoesNotExist() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {}
''');

    await assertErrorsInCode('''
import 'a.dart';
import 'b.dart';
void f(A _) {}
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 24, 8),
    ]);
  }

  test_part_inside_unnecessary() async {
    newFile('$testPackageLibPath/x.dart', '''
class A {}
class B {}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'x.dart' hide B;
import 'x.dart';
void f(A _, B _) {}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(HintCode.UNNECESSARY_IMPORT, 25, 8),
    ]);
  }

  test_part_inside_unnecessary_prefixed() async {
    newFile('$testPackageLibPath/x.dart', '''
class A {}
class B {}
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
part 'b.dart';
''');

    var b = newFile('$testPackageLibPath/b.dart', r'''
part of 'a.dart';
import 'x.dart' as prefix hide B;
import 'x.dart' as prefix;
void f(prefix.A _, prefix.B _) {}
''');

    await assertErrorsInFile2(a, []);

    await assertErrorsInFile2(b, [
      error(HintCode.UNNECESSARY_IMPORT, 25, 8),
    ]);
  }
}
