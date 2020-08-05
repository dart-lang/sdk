// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
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
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Double {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 6),
    ]);
  }

  test_Float() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Float {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 5),
    ]);
  }

  test_Int16() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Int16 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 5),
    ]);
  }

  test_Int32() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Int32 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 5),
    ]);
  }

  test_Int64() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Int64 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 5),
    ]);
  }

  test_Int8() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Int8 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 4),
    ]);
  }

  test_Pointer() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Pointer {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 7),
    ]);
  }

  test_Struct() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
class C extends Struct {}
''');
  }

  test_Uint16() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Uint16 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 6),
    ]);
  }

  test_Uint32() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Uint32 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 6),
    ]);
  }

  test_Uint64() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Uint64 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 6),
    ]);
  }

  test_Uint8() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Uint8 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 5),
    ]);
  }

  test_Void() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C extends Void {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_EXTENDS, 35, 4),
    ]);
  }
}

@reflectiveTest
class SubtypeOfFfiClassInImplementsTest extends PubPackageResolutionTest {
  test_Double() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Double {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 6),
    ]);
  }

  test_Float() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Float {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 5),
    ]);
  }

  test_Int16() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Int16 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 5),
    ]);
  }

  test_Int32() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Int32 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 5),
    ]);
  }

  test_Int64() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Int64 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 5),
    ]);
  }

  test_Int8() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Int8 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 4),
    ]);
  }

  test_Pointer() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Pointer {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 7),
    ]);
  }

  test_Struct() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Struct {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 6),
    ]);
  }

  test_Uint16() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Uint16 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 6),
    ]);
  }

  test_Uint32() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Uint32 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 6),
    ]);
  }

  test_Uint64() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Uint64 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 6),
    ]);
  }

  test_Uint8() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Uint8 {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 5),
    ]);
  }

  test_Void() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C implements Void {}
''', [
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_IMPLEMENTS, 38, 4),
    ]);
  }
}

@reflectiveTest
class SubtypeOfFfiClassInWithTest extends PubPackageResolutionTest {
  test_Double() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Double {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 6),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 6),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 6),
    ]);
  }

  test_Float() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Float {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 5),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 5),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 5),
    ]);
  }

  test_Int16() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Int16 {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 5),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 5),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 5),
    ]);
  }

  test_Int32() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Int32 {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 5),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 5),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 5),
    ]);
  }

  test_Int64() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Int64 {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 5),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 5),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 5),
    ]);
  }

  test_Int8() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Int8 {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 4),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 4),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 4),
    ]);
  }

  test_Pointer() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Pointer {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 7),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 7),
    ]);
  }

  test_Struct() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Struct {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 6),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 6),
    ]);
  }

  test_Uint16() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Uint16 {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 6),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 6),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 6),
    ]);
  }

  test_Uint32() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Uint32 {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 6),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 6),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 6),
    ]);
  }

  test_Uint64() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Uint64 {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 6),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 6),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 6),
    ]);
  }

  test_Uint8() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Uint8 {}
''', [
      error(CompileTimeErrorCode.MIXIN_CLASS_DECLARES_CONSTRUCTOR, 32, 5),
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 5),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 5),
    ]);
  }

  test_Void() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class C with Void {}
''', [
      error(CompileTimeErrorCode.MIXIN_INHERITS_FROM_NOT_OBJECT, 32, 4),
      error(FfiCode.SUBTYPE_OF_FFI_CLASS_IN_WITH, 32, 4),
    ]);
  }
}
