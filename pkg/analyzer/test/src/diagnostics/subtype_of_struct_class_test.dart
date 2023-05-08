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
    await assertErrorsInCode(r'''
import 'dart:ffi';
final class S extends Struct {
  external Pointer notEmpty;
}
final class C extends S {}
''', [
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS, 103, 1),
    ]);
  }

  test_extends_union() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
final class S extends Union {
  external Pointer notEmpty;
}
final class C extends S {}
''', [
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_EXTENDS, 102, 1),
    ]);
  }
}

@reflectiveTest
class SubtypeOfStructClassInImplementsTest extends PubPackageResolutionTest {
  test_implements_abi_specific_int() async {
    await assertErrorsInCode(r'''
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
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 216,
          19),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS, 216, 19),
    ]);
  }

  test_implements_struct() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
final class S extends Struct {}
final class C implements S {}
''', [
      error(FfiCode.EMPTY_STRUCT, 31, 1),
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 76,
          1),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS, 76, 1),
    ]);
  }

  test_implements_struct_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
import 'dart:ffi';
final class S extends Struct {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as lib1;
class C implements lib1.S {}
''', [
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 47,
          6),
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 47,
          6),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS, 47, 6),
    ]);
  }

  test_implements_union() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
final class S extends Union {}
final class C implements S {}
''', [
      error(FfiCode.EMPTY_STRUCT, 31, 1),
      error(CompileTimeErrorCode.BASE_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 75,
          1),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_IMPLEMENTS, 75, 1),
    ]);
  }
}

@reflectiveTest
class SubtypeOfStructClassInWithTest extends PubPackageResolutionTest {
  test_with_struct() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
final class S extends Struct {}
final class C with S {}
''', [
      error(FfiCode.EMPTY_STRUCT, 31, 1),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 70, 1),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH, 70, 1,
          messageContains: ["class 'C'", "mix in 'S'"]),
    ]);
  }

  test_with_struct_prefixed() async {
    newFile('$testPackageLibPath/lib1.dart', '''
import 'dart:ffi';
final class S extends Struct {}
''');
    await assertErrorsInCode(r'''
import 'lib1.dart' as lib1;

class C with lib1.S {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 42, 6),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH, 42, 6,
          messageContains: ["class 'C'", "mix in 'S'"]),
    ]);
  }

  test_with_union() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
final class S extends Union {}
final class C with S {}
''', [
      error(FfiCode.EMPTY_STRUCT, 31, 1),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 69, 1),
      error(FfiCode.SUBTYPE_OF_STRUCT_CLASS_IN_WITH, 69, 1),
    ]);
  }
}
