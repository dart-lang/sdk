// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../generated/test_support.dart';
import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BaseClassImplementedOutsideOfLibraryTest);
  });
}

@reflectiveTest
class BaseClassImplementedOutsideOfLibraryTest
    extends PubPackageResolutionTest {
  test_class_inside() async {
    await assertNoErrorsInCode(r'''
base class Foo {}
base class Bar implements Foo {}
''');
  }

  test_class_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
base class Bar implements Foo {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 45,
          3),
    ]);
  }

  test_class_outside_sealed() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
sealed class B extends A {}
base class C implements B {}
''', [
      error(
        CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY,
        69,
        1,
        text:
            "The class 'A' can't be implemented outside of its library because it's a base class.",
        contextMessages: [
          ExpectedContextMessage(a.path, 11, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_class_outside_sealed_noBase() async {
    // Instead of emitting [SUBTYPE_OF_BASE_IS_NOT_BASE_FINAL_OR_SEALED], we
    // tell the user that they can't implement an indirect base supertype.
    final a = newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
sealed class B extends A {}
class C implements B {}
''', [
      error(
        CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY,
        64,
        1,
        text:
            "The class 'A' can't be implemented outside of its library because it's a base class.",
        contextMessages: [
          ExpectedContextMessage(a.path, 11, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_class_outside_viaExtends() async {
    newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
base class B extends A {}
base class C implements B {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 67,
          1),
    ]);
  }

  test_class_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
base class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 45,
          10),
    ]);
  }

  test_class_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
base class Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 71,
          10),
    ]);
  }

  test_classTypeAlias_inside() async {
    await assertNoErrorsInCode(r'''
base class A {}
sealed class B extends A {}
mixin M {}
base class C = Object with M implements B;
''');
  }

  test_classTypeAlias_outside() async {
    final a = newFile('$testPackageLibPath/a.dart', r'''
base class A {}
''');

    await assertErrorsInCode(r'''
import 'a.dart';
sealed class B extends A {}
mixin M {}
base class C = Object with M implements B;
''', [
      error(
        CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY,
        96,
        1,
        text:
            "The class 'A' can't be implemented outside of its library because it's a base class.",
        contextMessages: [
          ExpectedContextMessage(a.path, 11, 1,
              text:
                  "The type 'B' is a subtype of 'A', and 'A' is defined here.")
        ],
      ),
    ]);
  }

  test_enum_inside() async {
    await assertNoErrorsInCode(r'''
base class Foo {}
enum Bar implements Foo { bar }
''');
  }

  test_enum_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar implements Foo { bar }
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 39,
          3),
    ]);
  }

  test_enum_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
enum Bar implements FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 39,
          10),
    ]);
  }

  test_enum_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
enum Bar implements FooTypedef { bar }
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 65,
          10),
    ]);
  }

  test_mixin_inside() async {
    await assertNoErrorsInCode(r'''
base class Foo {}
base mixin Bar implements Foo {}
''');
  }

  test_mixin_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
base mixin Bar implements Foo {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 45,
          3),
    ]);
  }

  test_mixin_outside_viaTypedef_inside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
typedef FooTypedef = Foo;
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
base mixin Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 45,
          10),
    ]);
  }

  test_mixin_outside_viaTypedef_outside() async {
    newFile('$testPackageLibPath/foo.dart', r'''
base class Foo {}
''');

    await assertErrorsInCode(r'''
import 'foo.dart';
typedef FooTypedef = Foo;
base mixin Bar implements FooTypedef {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 71,
          10),
    ]);
  }
}
