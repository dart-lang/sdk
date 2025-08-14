// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SubtypeOfStructClassInExtendsTest);
    defineReflectiveTests(SubtypeOfStructClassInImplementsTest);
    defineReflectiveTests(SubtypeOfStructClassInWithTest);
  });
}

@reflectiveTest
class SubtypeOfStructClassInExtendsTest extends PubPackageResolutionTest {
  test_extends_struct() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class S extends Struct {
  external Pointer notEmpty;
}
final class C extends S {}
''',
      [error(FfiCode.subtypeOfStructClassInExtends, 103, 1)],
    );
  }

  test_extends_union() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class S extends Union {
  external Pointer notEmpty;
}
final class C extends S {}
''',
      [error(FfiCode.subtypeOfStructClassInExtends, 102, 1)],
    );
  }
}

@reflectiveTest
class SubtypeOfStructClassInImplementsTest extends PubPackageResolutionTest {
  test_implements_abi_specific_int() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
})
final class AbiSpecificInteger1 extends AbiSpecificInteger {
  const AbiSpecificInteger1();
}
final class AbiSpecificInteger4 implements AbiSpecificInteger1 {
  const AbiSpecificInteger4();
}
''',
      [
        error(
          CompileTimeErrorCode.baseClassImplementedOutsideOfLibrary,
          216,
          19,
        ),
        error(FfiCode.subtypeOfStructClassInImplements, 216, 19),
      ],
    );
  }

  test_implements_struct() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class S extends Struct {}
final class C implements S {}
''',
      [
        error(FfiCode.emptyStruct, 31, 1),
        error(CompileTimeErrorCode.baseClassImplementedOutsideOfLibrary, 76, 1),
        error(FfiCode.subtypeOfStructClassInImplements, 76, 1),
      ],
    );
  }

  test_implements_struct_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
import 'dart:ffi';
final class S extends Struct {}
''');
    await assertErrorsInCode(
      r'''
import 'lib1.dart' as lib1;
class C implements lib1.S {}
''',
      [
        error(CompileTimeErrorCode.baseClassImplementedOutsideOfLibrary, 47, 6),
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          47,
          6,
        ),
        error(FfiCode.subtypeOfStructClassInImplements, 47, 6),
      ],
    );
  }

  test_implements_union() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class S extends Union {}
final class C implements S {}
''',
      [
        error(FfiCode.emptyStruct, 31, 1),
        error(CompileTimeErrorCode.baseClassImplementedOutsideOfLibrary, 75, 1),
        error(FfiCode.subtypeOfStructClassInImplements, 75, 1),
      ],
    );
  }
}

@reflectiveTest
class SubtypeOfStructClassInWithTest extends PubPackageResolutionTest {
  test_with_struct() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class S extends Struct {}
final class C with S {}
''',
      [
        error(FfiCode.emptyStruct, 31, 1),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 70, 1),
        error(
          FfiCode.subtypeOfStructClassInWith,
          70,
          1,
          messageContains: ["class 'C'", "mix in 'S'"],
        ),
      ],
    );
  }

  test_with_struct_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
import 'dart:ffi';
final class S extends Struct {}
''');
    await assertErrorsInCode(
      r'''
import 'lib1.dart' as lib1;

class C with lib1.S {}
''',
      [
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 42, 6),
        error(
          FfiCode.subtypeOfStructClassInWith,
          42,
          6,
          messageContains: ["class 'C'", "mix in 'S'"],
        ),
      ],
    );
  }

  test_with_union() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
final class S extends Union {}
final class C with S {}
''',
      [
        error(FfiCode.emptyStruct, 31, 1),
        error(CompileTimeErrorCode.mixinInheritsFromNotObject, 69, 1),
        error(FfiCode.subtypeOfStructClassInWith, 69, 1),
      ],
    );
  }
}
