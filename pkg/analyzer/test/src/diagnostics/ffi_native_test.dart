// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FfiNativeTest);
  });
}

@reflectiveTest
class FfiNativeTest extends PubPackageResolutionTest {
  test_annotation_FfiNative_getters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class NativeFieldWrapperClass1 {}

class Paragraph extends NativeFieldWrapperClass1 {
  @FfiNative<Double Function(Pointer<Void>)>('Paragraph::ideographicBaseline', isLeaf: true)
  external double get ideographicBaseline;

  @FfiNative<Void Function(Pointer<Void>, Double)>('Paragraph::ideographicBaseline', isLeaf: true)
  external set ideographicBaseline(double d);
}
''', []);
  }

  test_annotation_FfiNative_noArguments() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@FfiNative
external int foo();
''', [
      error(CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, 20, 10),
    ]);
  }

  test_annotation_FfiNative_noTypeArguments() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@FfiNative()
external int foo();
''', [
      error(CompileTimeErrorCode.NOT_ENOUGH_POSITIONAL_ARGUMENTS, 30, 2),
    ]);
  }

  test_FfiNativeCanUseHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Handle Function(Handle)>('DoesntMatter')
external Object doesntMatter(Object);
''', []);
  }

  test_FfiNativeCanUseLeaf() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Int8 Function(Int64)>('DoesntMatter', isLeaf:true)
external int doesntMatter(int x);
''', []);
  }

  test_FfiNativeInstanceMethodsMustHaveReceiver() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class K {
  @FfiNative<Void Function(Double)>('DoesntMatter')
  external void doesntMatter(double x);
}
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER,
          31, 89),
    ]);
  }

  test_FfiNativeLeafMustNotReturnHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Handle Function()>('DoesntMatter', isLeaf:true)
external Object doesntMatter();
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 19, 90),
    ]);
  }

  test_FfiNativeLeafMustNotTakeHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Void Function(Handle)>('DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, 19, 100),
    ]);
  }

  test_FfiNativeNonFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<IntPtr Function(int)>('doesntmatter')
external int nonFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 19, 85),
    ]);
  }

  test_FfiNativeNonFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<double Function(IntPtr)>('doesntmatter')
external double nonFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 19, 92),
    ]);
  }

  test_FfiNativeTooFewParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Void Function(Double)>('DoesntMatter')
external void doesntMatter(double x, double y);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 19, 97),
    ]);
  }

  test_FfiNativeTooManyParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Void Function(Double, Double)>('DoesntMatter')
external void doesntMatter(double x);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 19, 95),
    ]);
  }

  test_FfiNativeVoidReturn() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<Handle Function(Uint32, Uint32, Handle)>('doesntmatter')
external void voidReturn(int width, int height, Object outImage);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 19, 133),
    ]);
  }

  test_FfiNativeWrongFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<IntPtr Function(Double)>('doesntmatter')
external int wrongFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 19, 90),
    ]);
  }

  test_FfiNativeWrongFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@FfiNative<IntPtr Function(IntPtr)>('doesntmatter')
external double wrongFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 19, 94),
    ]);
  }
}
