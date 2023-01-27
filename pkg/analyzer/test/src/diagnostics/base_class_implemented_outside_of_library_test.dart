// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BaseClassImplementedOutsideOfLibraryTest);
  });
}

@reflectiveTest
class BaseClassImplementedOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_class_implements_inside() async {
    await assertNoErrorsInCode(r'''
base class Foo {}
class Bar implements Foo {}
''');
  }

  test_class_implements_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar implements Foo {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 40,
          3),
    ]);
  }

  test_class_implements_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 40,
          10),
    ]);
  }

  test_class_implements_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 66,
          10),
    ]);
  }

  test_class_implements_subtypeOfBase_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
class Bar implements Foo {}
''');

    await assertNoErrorsInCode(r'''
import 'foo.dart';
class Bar2 implements Bar {}
''');
  }

  test_mixin_implements_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
mixin Bar implements Foo {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 40,
          3),
    ]);
  }
}
