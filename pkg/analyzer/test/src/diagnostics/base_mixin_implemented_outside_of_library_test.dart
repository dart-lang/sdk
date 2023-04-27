// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BaseMixinImplementedOutsideOfLibraryTest);
  });
}

@reflectiveTest
class BaseMixinImplementedOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_class_inside() async {
    await assertNoErrorsInCode(r'''
base mixin Foo {}
base class Bar implements Foo {}
''');
  }

  test_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
base class Bar implements Foo {}
''', [
      error(CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 45,
          3),
    ]);
  }

  test_class_outside_viaExtends() async {
    newFile('$testPackageLibPath/a.dart', r'''
base mixin A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';

sealed class B extends Object with A {}
class C implements B {}
''', [
      error(
          CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 77, 1,
          contextMessages: [message('/home/test/lib/a.dart', 11, 1)]),
    ]);
  }

  test_class_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
base class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 45,
          10),
    ]);
  }

  test_class_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
base class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 71,
          10),
    ]);
  }

  test_enum_inside() async {
    await assertNoErrorsInCode(r'''
base mixin Foo {}
enum Bar implements Foo { bar }
''');
  }

  test_enum_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar implements Foo { bar }
''', [
      error(CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 39,
          3),
    ]);
  }

  test_enum_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar implements FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 39,
          10),
    ]);
  }

  test_enum_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
enum Bar implements FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 65,
          10),
    ]);
  }

  test_mixin_inside() async {
    await assertNoErrorsInCode(r'''
base mixin Foo {}
base mixin Bar implements Foo {}
''');
  }

  test_mixin_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
base mixin Bar implements Foo {}
''', [
      error(CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 45,
          3),
    ]);
  }

  test_mixin_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
base mixin Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 45,
          10),
    ]);
  }

  test_mixin_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base mixin Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
base mixin Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_MIXIN_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 71,
          10),
    ]);
  }
}
