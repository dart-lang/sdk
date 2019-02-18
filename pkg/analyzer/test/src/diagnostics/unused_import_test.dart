// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(UnusedImportTest);
  });
}

@reflectiveTest
class UnusedImportTest extends DriverResolutionTest {
  test_annotationOnDirective() async {
    newFile('/test/lib/lib1.dart', content: r'''
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
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart';
import 'lib1.dart' as one;
one.A a;
''', [HintCode.UNUSED_IMPORT]);
  }

  test_as_equalPrefixes_referenced() async {
    // 18818
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
''');
    newFile('/test/lib/lib2.dart', content: r'''
class B {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a;
one.B b;
''');
  }

  @failingTest
  test_as_equalPrefixes_unreferenced() async {
    // See todo at ImportsVerifier.prefixElementMap.
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
''');
    newFile('/test/lib/lib2.dart', content: r'''
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as one;
import 'lib2.dart' as one;
one.A a;
''', [HintCode.UNUSED_IMPORT]);
  }

  test_core_library() async {
    await assertNoErrorsInCode(r'''
import 'dart:core';
''');
  }

  test_export() async {
    newFile('/test/lib/lib1.dart', content: r'''
export 'lib2.dart';
class One {}
''');
    newFile('/test/lib/lib2.dart', content: r'''
class Two {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
Two two;
''');
  }

  test_export2() async {
    newFile('/test/lib/lib1.dart', content: r'''
export 'lib2.dart';
class One {}
''');
    newFile('/test/lib/lib2.dart', content: r'''
export 'lib3.dart';
class Two {}
''');
    newFile('/test/lib/lib3.dart', content: r'''
class Three {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
Three three;
''');
  }

  test_export_infiniteLoop() async {
    newFile('/test/lib/lib1.dart', content: r'''
export 'lib2.dart';
class One {}
''');
    newFile('/test/lib/lib2.dart', content: r'''
export 'lib3.dart';
class Two {}
''');
    newFile('/test/lib/lib3.dart', content: r'''
export 'lib2.dart';
class Three {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart';
Two two;
''');
  }

  test_hide() async {
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart';
import 'lib1.dart' hide A;
A a;
''', [HintCode.UNUSED_IMPORT]);
  }

  test_inComment_libraryDirective() async {
    await assertNoErrorsInCode(r'''
/// Use [Future] class.
import 'dart:async';
''');
  }

  test_metadata() async {
    newFile('/test/lib/lib1.dart', content: r'''
const x = 0;
''');
    await assertNoErrorsInCode(r'''
@A(x)
import 'lib1.dart';
class A {
  final int value;
  const A(this.value);
}
''');
  }

  test_prefix_topLevelFunction() async {
    newFile('/test/lib/lib1.dart', content: r'''
class One {}
topLevelFunction() {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
class A {
  static void x() {
    One o;
    one.topLevelFunction();
  }
}
''');
  }

  test_prefix_topLevelFunction2() async {
    newFile('/test/lib/lib1.dart', content: r'''
class One {}
topLevelFunction() {}
''');
    await assertNoErrorsInCode(r'''
import 'lib1.dart' hide topLevelFunction;
import 'lib1.dart' as one show topLevelFunction;
import 'lib1.dart' as two show topLevelFunction;
class A {
  static void x() {
    One o;
    one.topLevelFunction();
    two.topLevelFunction();
  }
}
''');
  }

  test_show() async {
    newFile('/test/lib/lib1.dart', content: r'''
class A {}
class B {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' show A;
import 'lib1.dart' show B;
A a;
''', [HintCode.UNUSED_IMPORT]);
  }

  test_unusedImport() async {
    newFile('/test/lib/lib1.dart');
    await assertErrorsInCode(r'''
import 'lib1.dart';
''', [HintCode.UNUSED_IMPORT]);
  }
}
