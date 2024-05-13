// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalClassImplementedOutsideOfLibraryTest);
  });
}

@reflectiveTest
class FinalClassImplementedOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_class_inside() async {
    await assertNoErrorsInCode(r'''
final class Foo {}
final class Bar implements Foo {}
''');
  }

  test_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
final class Bar implements Foo {}
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 46,
          3),
    ]);
  }

  test_class_outside_viaLanguage219AndCore() async {
    var a = newFile('$testPackageLibPath/a.dart', r'''
// @dart=2.19
import 'dart:core';
class A implements MapEntry<int, int> {
  int get key => 0;
  int get value => 1;
}
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    await assertErrorsInCode(r'''
import 'a.dart';
final class B implements A {
  int get key => 0;
  int get value => 1;
}
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 42,
          1),
    ]);
  }

  test_class_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
final class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 46,
          10),
    ]);
  }

  test_class_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
final class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 72,
          10),
    ]);
  }

  test_enum_inside() async {
    await assertNoErrorsInCode(r'''
final class Foo {}
enum Bar implements Foo { bar }
''');
  }

  test_enum_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar implements Foo { bar }
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 39,
          3),
    ]);
  }

  test_enum_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar implements FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 39,
          10),
    ]);
  }

  test_enum_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
enum Bar implements FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 65,
          10),
    ]);
  }

  test_enum_subtypeOfFinal_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final class Foo {}
class Bar implements Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
enum Bar2 implements Bar { bar }
''');
  }
}
