// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalMixinMixedInOutsideOfLibraryTest);
  });
}

@reflectiveTest
class FinalMixinMixedInOutsideOfLibraryTest extends PubPackageResolutionTest {
  test_class_inside() async {
    await assertNoErrorsInCode(r'''
final mixin Foo {}
final class Bar with Foo {}
''');
  }

  test_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
final class Bar with Foo {}
''', [
      error(
          CompileTimeErrorCode.FINAL_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY, 40, 3),
    ]);
  }

  test_class_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
final class Bar with FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.FINAL_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY, 40, 10),
    ]);
  }

  test_class_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
final class Bar with FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.FINAL_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY, 66, 10),
    ]);
  }

  test_enum_inside() async {
    await assertNoErrorsInCode(r'''
final mixin Foo {}
enum Bar with Foo { bar }
''');
  }

  test_enum_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar with Foo { bar }
''', [
      error(
          CompileTimeErrorCode.FINAL_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY, 33, 3),
    ]);
  }

  test_enum_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar with FooTypedef { bar }
''', [
      error(
          CompileTimeErrorCode.FINAL_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY, 33, 10),
    ]);
  }

  test_enum_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
final mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
enum Bar with FooTypedef { bar }
''', [
      error(
          CompileTimeErrorCode.FINAL_MIXIN_MIXED_IN_OUTSIDE_OF_LIBRARY, 59, 10),
    ]);
  }
}
