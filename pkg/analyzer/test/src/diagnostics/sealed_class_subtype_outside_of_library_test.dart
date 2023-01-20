// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SealedClassSubtypeOutsideOfLibraryTest);
  });
}

@reflectiveTest
class SealedClassSubtypeOutsideOfLibraryTest extends PubPackageResolutionTest {
  test_class_extends_sealed_inside() async {
    await assertNoErrorsInCode(r'''
sealed class Foo {}
class Bar extends Foo {}
''');
  }

  test_class_extends_sealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar extends Foo {}
''', [
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 19, 24),
    ]);
  }

  test_class_extends_sealed_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar extends FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 19, 31),
    ]);
  }

  test_class_extends_sealed_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar extends FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 45, 31),
    ]);
  }

  test_class_extends_subtypeOfSealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
class Bar extends Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar2 extends Bar {}
''');
  }

  test_class_implements_sealed_inside() async {
    await assertNoErrorsInCode(r'''
sealed class Foo {}
class Bar implements Foo {}
''');
  }

  test_class_implements_sealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar implements Foo {}
''', [
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 19, 27),
    ]);
  }

  test_class_implements_sealed_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar implements FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 19, 34),
    ]);
  }

  test_class_implements_sealed_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar implements FooTypedef {}
''', [
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 45, 34),
    ]);
  }

  test_class_implements_subtypeOfSealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
class Bar implements Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar2 implements Bar {}
''');
  }

  test_class_with_sealed_inside() async {
    await assertNoErrorsInCode(r'''
sealed class Foo {}
class Bar with Foo {}
''');
  }

  test_class_with_sealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar with Foo {}
''', [
      error(CompileTimeErrorCode.CLASS_USED_AS_MIXIN, 19, 21),
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 19, 21),
    ]);
  }

  test_class_with_sealed_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar with FooTypedef {}
''', [
      error(CompileTimeErrorCode.CLASS_USED_AS_MIXIN, 19, 28),
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 19, 28),
    ]);
  }

  test_class_with_sealed_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar with FooTypedef {}
''', [
      error(CompileTimeErrorCode.CLASS_USED_AS_MIXIN, 45, 28),
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 45, 28),
    ]);
  }

  test_class_with_subtypeOfSealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
class Bar with Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar2 extends Bar {}
''');
  }

  test_mixin_implements_sealed_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
sealed class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
mixin Bar implements Foo {}
''', [
      error(
          CompileTimeErrorCode.SEALED_CLASS_SUBTYPE_OUTSIDE_OF_LIBRARY, 19, 27),
    ]);
  }
}
