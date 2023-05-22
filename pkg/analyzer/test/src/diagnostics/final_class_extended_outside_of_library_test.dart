// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalClassExtendedOutsideOfLibraryTest);
  });
}

@reflectiveTest
class FinalClassExtendedOutsideOfLibraryTest extends PubPackageResolutionTest {
  test_inside() async {
    await assertNoErrorsInCode(r'''
final class Foo {}
final class Bar extends Foo {}
''');
  }

  test_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
final class Bar extends Foo {}
''', [
      error(
          CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY, 43, 3),
    ]);
  }

  test_outside_viaLanguage219AndCore() async {
    // There is no error when extending a pre-feature class that subtypes a
    // class in the core libraries.
    final a = newFile('$testPackageLibPath/a.dart', r'''
// @dart=2.19
import 'dart:core';
class A implements MapEntry<int, int> {
  int get key => 0;
  int get value => 1;
}
''');

    await resolveFile2(a.path);
    assertNoErrorsInResult();

    await assertNoErrorsInCode(r'''
import 'a.dart';
final class B extends A {
  int get key => 0;
  int get value => 1;
}
''');
  }

  test_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
final class Bar extends FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY, 43, 10),
    ]);
  }

  test_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
final class Bar extends FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY, 69, 10),
    ]);
  }
}
