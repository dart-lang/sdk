// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfFfiClassInExtendsTest);
    defineReflectiveTests(SubtypeOfFfiClassInImplementsTest);
    defineReflectiveTests(SubtypeOfFfiClassInWithTest);
  });
}

@reflectiveTest
class SubtypeOfFfiClassInExtendsTest extends PubPackageResolutionTest {
  test_Double() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class C extends Double {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 41, 6)],
    );
  }

  test_Double_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
import 'dart:ffi';
class C extends Double {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 49, 6)],
    );
  }

  test_Finalizable() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Finalizable {}
''',
      [
        error(
          CompileTimeErrorCode.noGenerativeConstructorsInSuperclass,
          35,
          11,
        ),
      ],
    );
  }

  test_Float() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Float {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 5)],
    );
  }

  test_Int16() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Int16 {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 5)],
    );
  }

  test_Int32() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Int32 {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 5)],
    );
  }

  test_Int64() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Int64 {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 5)],
    );
  }

  test_Int8() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Int8 {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 4)],
    );
  }

  test_Pointer() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Pointer {
  external factory C();
}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 7)],
    );
  }

  test_Struct() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
final class C extends Struct {
  external Pointer notEmpty;
}
''');
  }

  test_Uint16() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Uint16 {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 6)],
    );
  }

  test_Uint32() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Uint32 {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 6)],
    );
  }

  test_Uint64() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Uint64 {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 6)],
    );
  }

  test_Uint8() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Uint8 {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 5)],
    );
  }

  test_Union() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
final class C extends Union {
  external Pointer notEmpty;
}
''');
  }

  test_Void() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C extends Void {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 35, 4)],
    );
  }
}

@reflectiveTest
class SubtypeOfFfiClassInImplementsTest extends PubPackageResolutionTest {
  test_Double() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Double {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          6,
        ),
      ],
    );
  }

  test_Double_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
import 'dart:ffi';
class C implements Double {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          52,
          6,
        ),
      ],
    );
  }

  test_Double_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi' as ffi;
class C implements ffi.Double {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          45,
          10,
        ),
      ],
    );
  }

  test_Finalizable() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C implements Finalizable {}
''');
  }

  test_Float() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Float {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          5,
        ),
      ],
    );
  }

  test_Int16() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Int16 {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          5,
        ),
      ],
    );
  }

  test_Int32() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Int32 {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          5,
        ),
      ],
    );
  }

  test_Int64() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Int64 {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          5,
        ),
      ],
    );
  }

  test_Int8() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Int8 {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          4,
        ),
      ],
    );
  }

  test_Pointer() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Pointer {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          7,
        ),
        error(
          CompileTimeErrorCode.nonAbstractClassInheritsAbstractMemberOne,
          25,
          1,
        ),
      ],
    );
  }

  test_Struct() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class C implements Struct {}
''',
      [error(CompileTimeErrorCode.baseClassImplementedOutsideOfLibrary, 44, 6)],
    );
  }

  test_Uint16() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Uint16 {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          6,
        ),
      ],
    );
  }

  test_Uint32() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Uint32 {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          6,
        ),
      ],
    );
  }

  test_Uint64() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Uint64 {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          6,
        ),
      ],
    );
  }

  test_Uint8() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Uint8 {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          5,
        ),
      ],
    );
  }

  test_Union() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class C implements Union {}
''',
      [error(CompileTimeErrorCode.baseClassImplementedOutsideOfLibrary, 44, 5)],
    );
  }

  test_Void() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C implements Void {}
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          38,
          4,
        ),
      ],
    );
  }
}

@reflectiveTest
class SubtypeOfFfiClassInWithTest extends PubPackageResolutionTest {
  test_Double() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Double {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 6)],
    );
  }

  test_Double_language219() async {
    await assertErrorsInCode(
      r'''
// @dart=2.19
import 'dart:ffi';
class C with Double {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 46, 6)],
    );
  }

  test_Double_prefixed() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi' as ffi;
class C with ffi.Double {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 39, 10)],
    );
  }

  test_Float() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Float {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 5)],
    );
  }

  test_Int16() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Int16 {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 5)],
    );
  }

  test_Int32() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Int32 {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 5)],
    );
  }

  test_Int64() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Int64 {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 5)],
    );
  }

  test_Int8() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Int8 {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 4)],
    );
  }

  test_Pointer() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Pointer {}
''',
      [error(CompileTimeErrorCode.classUsedAsMixin, 32, 7)],
    );
  }

  test_Struct() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class C with Struct {}
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 38, 6)],
    );
  }

  test_Uint16() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Uint16 {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 6)],
    );
  }

  test_Uint32() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Uint32 {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 6)],
    );
  }

  test_Uint64() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Uint64 {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 6)],
    );
  }

  test_Uint8() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Uint8 {}
''',
      [error(CompileTimeErrorCode.mixinClassDeclaresConstructor, 32, 5)],
    );
  }

  test_Union() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class C with Union {}
''',
      [error(CompileTimeErrorCode.mixinInheritsFromNotObject, 38, 5)],
    );
  }

  test_Void() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class C with Void {}
''',
      [error(CompileTimeErrorCode.classUsedAsMixin, 32, 4)],
    );
  }
}
