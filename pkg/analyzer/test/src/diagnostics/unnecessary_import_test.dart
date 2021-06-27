// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    // TODO(srawlins): Re-enable this check once Flutter engine path is clear.
    // defineReflectiveTests(UnnecessaryImportTest);
  });
}

@reflectiveTest
class UnnecessaryImportTest extends PubPackageResolutionTest {
  test_annotationOnDirective() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
class A {
  const A() {}
}
''');
    await assertNoErrorsInCode(r'''
@A()
import 'lib1.dart';
''');
  }

  test_as() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', content: '''
export 'lib1.dart';
class B {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart' as two;
f(A a, two.B b) {}
''');
  }

  test_as_differentPrefixes() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', content: '''
export 'lib1.dart';
class B {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart' as one;
import 'lib2.dart' as two;
f(one.A a, two.B b) {}
''');
  }

  test_as_equalPrefixes_referenced() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', content: r'''
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one;
f(one.A a, one.B b) {}
''');
  }

  test_as_equalPrefixes_referenced_via_export() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', content: r'''
class B {}
''');
    newFile('$testPackageLibPath/lib3.dart', content: r'''
export 'lib2.dart';
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib3.dart' as one;
f(one.A a, one.B b) {}
''');
  }

  test_as_equalPrefixes_unreferenced() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', content: r'''
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one; // ignore: unused_import
f(one.A a) {}
''');
  }

  test_as_show_multipleElements() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
class A {}
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one show A, B;
f(one.A a, one.B b) {}
''');
  }

  test_as_showTopLevelFunction() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
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

  test_as_showTopLevelFunction_multipleDirectives() async {
    newFile('$testPackageLibPath/lib1.dart', content: r'''
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

  test_as_systemShadowing() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
class File {}
''');
    await assertNoErrorsInCode('''
import 'dart:io' as io;
import 'lib1.dart' as io;
g(io.Directory d, io.File f) {}
''');
  }

  test_as_unnecessary() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', content: '''
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

  test_duplicteImport_differentPrefix() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
class A {}
class B {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';
import 'lib1.dart' as p;
f(A a1, p.A a2, B b) {}
''');
  }

  test_hide() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', content: '''
export 'lib1.dart' hide A;
class B {}
''');
    await assertNoErrorsInCode('''
import 'lib1.dart';
import 'lib2.dart';
f(A a, B b) {}
''');
  }

  test_systemShadowing() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
class File {}
''');
    await assertNoErrorsInCode('''
import 'dart:io';
import 'lib1.dart';
g(Directory d, File f) {}
''');
  }

  test_unnecessaryImport() async {
    newFile('$testPackageLibPath/lib1.dart', content: '''
class A {}
''');
    newFile('$testPackageLibPath/lib2.dart', content: '''
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
}
