// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/ffi_code.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddressOfTest);
    defineReflectiveTests(DefaultAssetTest);
    defineReflectiveTests(FfiNativeTest);
    defineReflectiveTests(NativeFieldTest);
    defineReflectiveTests(NativeTest);
  });
}

@reflectiveTest
class AddressOfTest extends PubPackageResolutionTest {
  test_invalid_Lambda() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

void main() => print(Native.addressOf(() => 3));
''', [
      error(FfiCode.ARGUMENT_MUST_BE_NATIVE, 58, 7),
    ]);
  }

  test_invalid_MismatchedInferredType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native()
external Pointer<IntPtr> global;

void main() => print(Native.addressOf<Pointer<Double>>(global));
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 85, 41),
    ]);
  }

  test_invalid_MismatchingType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

void main() {
  print(Native.addressOf<NativeFunction<Int8 Function()>>(foo));
}
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 91, 54),
    ]);
  }

  test_invalid_MissingType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

void main() {
  print(Native.addressOf(foo));
}
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 91, 21),
    ]);
  }

  test_invalid_NotAConstant() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();
@Native<Void Function()>()
external void bar();

void entry(bool condition) {
  print(Native.addressOf(condition ? foo : bar));
}
''', [
      error(FfiCode.ARGUMENT_MUST_BE_NATIVE, 171, 21),
    ]);
  }

  test_invalid_String() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

void main() => print(Native.addressOf('malloc'));
''', [
      error(FfiCode.ARGUMENT_MUST_BE_NATIVE, 58, 8),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

@Native()
external Pointer<IntPtr> global;

void main() {
  print(Native.addressOf<NativeFunction<Void Function()>>(foo));
  print(Native.addressOf<Pointer<IntPtr>>(global));
}
''');
  }
}

@reflectiveTest
class DefaultAssetTest extends PubPackageResolutionTest {
  test_invalid_duplicate() async {
    await assertErrorsInCode(r'''
@DefaultAsset('foo')
@DefaultAsset('bar')
library;

import 'dart:ffi';
''', [
      error(FfiCode.FFI_NATIVE_INVALID_DUPLICATE_DEFAULT_ASSET, 22, 12),
    ]);
  }

  test_invalid_duplicateFromConst() async {
    await assertErrorsInCode(r'''
@DefaultAsset('bar')
@defaults
library;

import 'dart:ffi';

const defaults = DefaultAsset('foo');
''', [
      error(FfiCode.FFI_NATIVE_INVALID_DUPLICATE_DEFAULT_ASSET, 22, 8),
    ]);
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
@DefaultAsset('bar')
library;

import 'dart:ffi';

@Native<Void Function()>()
external void foo();
''');
  }

  test_validFromConst() async {
    await assertNoErrorsInCode(r'''
@defaults
library;

import 'dart:ffi';

const defaults = DefaultAsset('foo');

@Native<Void Function()>()
external void foo();
''');
  }
}

@reflectiveTest
class FfiNativeTest extends PubPackageResolutionTest {
  test_annotation_FfiNative_getters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

base class NativeFieldWrapperClass1 {}

base class Paragraph extends NativeFieldWrapperClass1 {
  @Native<Double Function(Pointer<Void>)>(symbol: 'Paragraph::ideographicBaseline', isLeaf: true)
  external double get ideographicBaseline;

  @Native<Void Function(Pointer<Void>, Double)>(symbol: 'Paragraph::ideographicBaseline', isLeaf: true)
  external set ideographicBaseline(double d);
}
''', []);
  }

  test_annotation_FfiNative_noArguments() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native
external int foo();
''', [
      error(CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, 20, 7),
    ]);
  }

  test_annotation_FfiNative_noTypeArguments() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native()
external int foo();
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 43, 3),
    ]);
  }

  test_FfiNativeCanUseHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Handle Function(Handle)>(symbol: 'DoesntMatter')
external Object doesntMatter(Object);
''', []);
  }

  test_FfiNativeCanUseLeaf() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64)>(symbol: 'DoesntMatter', isLeaf:true)
external int doesntMatter(int x);
''', []);
  }

  test_FfiNativeInstanceMethodsMustHaveReceiver() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class K {
  @Native<Void Function(Double)>(symbol: 'DoesntMatter')
  external void doesntMatter(double x);
}
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER,
          102, 12),
    ]);
  }

  test_FfiNativeLeafMustNotReturnHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Handle Function()>(symbol: 'DoesntMatter', isLeaf:true)
external Object doesntMatter();
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 99, 12),
    ]);
  }

  test_FfiNativeLeafMustNotTakeHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, 101, 12),
    ]);
  }

  test_FfiNativeNonFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(int)>(symbol: 'doesntmatter')
external int nonFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 86, 15),
    ]);
  }

  test_FfiNativeNonFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<double Function(IntPtr)>(symbol: 'doesntmatter')
external double nonFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 92, 16),
    ]);
  }

  test_FfiNativePointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Pointer)>(symbol: 'free')
external void posixFree(Pointer pointer);
''');
  }

  test_FfiNativeTooFewParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Double)>(symbol: 'DoesntMatter')
external void doesntMatter(double x, double y);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 88, 12),
    ]);
  }

  test_FfiNativeTooManyParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Double, Double)>(symbol: 'DoesntMatter')
external void doesntMatter(double x);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 96, 12),
    ]);
  }

  test_FfiNativeVoidReturn() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Handle Function(Uint32, Uint32, Handle)>(symbol: 'doesntmatter')
external void voidReturn(int width, int height, Object outImage);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 106, 10),
    ]);
  }

  test_FfiNativeWrongFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(Double)>(symbol: 'doesntmatter')
external int wrongFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 89, 17),
    ]);
  }

  test_FfiNativeWrongFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>(symbol: 'doesntmatter')
external double wrongFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 92, 18),
    ]);
  }
}

@reflectiveTest
class NativeFieldTest extends PubPackageResolutionTest {
  test_AbiSpecific() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native<Int>()
external int foo;
''');
  }

  test_Accessors() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native<IntPtr>()
external int get foo;

@Native<IntPtr>()
external set foo(int value);
''');
  }

  test_Array_InvalidDimension() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native()
@Array(0)
external Array<IntPtr> field;
''', [
      error(FfiCode.NON_POSITIVE_ARRAY_DIMENSION, 37, 1),
    ]);
  }

  test_Array_InvalidDimensionCount() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native()
@Array(10, 20)
external Array<IntPtr> field;
''', [
      error(FfiCode.SIZE_ANNOTATION_DIMENSIONS, 30, 14),
    ]);
  }

  test_Array_MissingAnnotation() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native()
external Array<IntPtr> field;
''', [
      error(FfiCode.MISSING_SIZE_ANNOTATION_CARRAY, 53, 5),
    ]);
  }

  test_Array_Valid() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
@Array(12)
external Array<IntPtr> field0;

@Array(10, 20)
@Native()
external Array<Array<IntPtr>> field1;

''');
  }

  test_Infer() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

final class MyStruct extends Struct {
  external Pointer<MyStruct> next;
}

@Native()
external MyStruct first;

@Native()
external Pointer<MyStruct> last;
''');
  }

  test_InvalidFunctionType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>()
external int field;
''', [
      error(FfiCode.NATIVE_FIELD_INVALID_TYPE, 67, 5),
    ]);
  }

  test_InvalidInstanceMember() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

class Foo {
  @Native<IntPtr>()
  external int field;
}
''', [
      error(FfiCode.NATIVE_FIELD_NOT_STATIC, 67, 5),
    ]);
  }

  test_InvalidNotExternal() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native<IntPtr>()
int field;
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_VARIABLE, 42, 5),
      error(FfiCode.FFI_NATIVE_MUST_BE_EXTERNAL, 42, 5),
    ]);
  }

  test_MismatchingFunctionType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native<NativeFunction<Double Function()>>()
external int Function() field;
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 89, 5),
    ]);
  }

  test_MismatchingType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native<Double>()
external int field;
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 51, 5),
    ]);
  }

  test_MissingType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native()
external int invalid;

@Native()
external Pointer<IntPtr> valid;
''', [
      error(FfiCode.NATIVE_FIELD_MISSING_TYPE, 43, 7),
    ]);
  }

  test_Unsupported_Function() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native<NativeFunction<Void Function()>>()
external void Function() field;
''', [
      error(FfiCode.NATIVE_FIELD_INVALID_TYPE, 88, 5),
    ]);
  }

  test_Unsupported_Handle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native<Handle>()
external Object field;
''', [
      error(FfiCode.NATIVE_FIELD_INVALID_TYPE, 54, 5),
    ]);
  }
}

@reflectiveTest
class NativeTest extends PubPackageResolutionTest {
  test_annotation_InvalidFieldType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native<IntPtr>()
external int foo();
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 51, 3),
    ]);
  }

  test_annotation_MissingType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native()
external int foo();
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 43, 3),
    ]);
  }

  test_annotation_MissingTypeConst() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

const a = Native();

@a
external int foo();
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 57, 3),
    ]);
  }

  test_annotation_Native_getters() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

base class NativeFieldWrapperClass1 {}

base class Paragraph extends NativeFieldWrapperClass1 {
  @Native<Double Function(Pointer<Void>)>(isLeaf: true)
  external double get ideographicBaseline;

  @Native<Void Function(Pointer<Void>, Double)>(isLeaf: true)
  external set ideographicBaseline(double d);
}
''');
  }

  test_annotation_Native_noArguments() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

@Native
external int foo();
''', [
      error(CompileTimeErrorCode.NO_ANNOTATION_CONSTRUCTOR_ARGUMENTS, 20, 7),
    ]);
  }

  test_NativeCanUseHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Handle Function(Handle)>()
external Object doesntMatter(Object);
''', []);
  }

  test_NativeCanUseLeaf() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64)>(isLeaf:true)
external int doesntMatter(int x);
''', []);
  }

  test_NativeDuplicateAnnotation() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Int32 Function(Int32)>()
@Native<Int32 Function(Int32)>(isLeaf: true)
external int foo(int v);
''', [
      error(FfiCode.FFI_NATIVE_INVALID_MULTIPLE_ANNOTATIONS, 53, 6),
    ]);
  }

  test_NativeDuplicateAnnotationConst() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';

const duplicate = Native<Int32 Function(Int32)>(isLeaf: true);

@Native<Int32 Function(Int32)>()
@duplicate
external int foo(int v);
''', [
      error(FfiCode.FFI_NATIVE_INVALID_MULTIPLE_ANNOTATIONS, 118, 9),
    ]);
  }

  test_NativeFromConst() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

const annotation = Native<Int32 Function(Int32)>();

@annotation
external int wrongFfiReturnType(int v);
''');
  }

  test_NativeInstanceMethodsMustHaveReceiver() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
class K {
  @Native<Void Function(Double)>()
  external void doesntMatter(double x);
}
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS_WITH_RECEIVER,
          80, 12),
    ]);
  }

  test_NativeLeafMustNotReturnHandle() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Handle Function()>(isLeaf:true)
external Object doesntMatter();
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 75, 12),
    ]);
  }

  test_NativeLeafMustNotReturnHandleConst() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
const annotation = Native<Handle Function()>(isLeaf:true);

@annotation
external Object doesntMatter();
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_RETURN_HANDLE, 107, 12),
    ]);
  }

  test_NativeLeafMustNotTakeHandles() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, 101, 12),
    ]);
  }

  test_NativeLeafMustNotTakeHandlesConst() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
const annotation = Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true);

@annotation
external void doesntMatter(Object o);
''', [
      error(FfiCode.LEAF_CALL_MUST_NOT_TAKE_HANDLE, 133, 12),
    ]);
  }

  test_NativeNonFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(int)>()
external int nonFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 64, 15),
    ]);
  }

  test_NativeNonFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<double Function(IntPtr)>()
external double nonFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_NATIVE_FUNCTION_TYPE, 70, 16),
    ]);
  }

  test_NativePointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Pointer)>()
external void free(Pointer pointer);
''');
  }

  test_NativeTooFewParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Double)>()
external void doesntMatter(double x, double y);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 66, 12),
    ]);
  }

  test_NativeTooManyParameters() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Double, Double)>()
external void doesntMatter(double x);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 74, 12),
    ]);
  }

  test_NativeVarArgs() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64, VarArgs<(Int32, Double)>)>()
external int doesntMatter(int x, int y, double z);
''');
  }

  test_NativeVarArgsTooFew() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64, VarArgs<(Int32, Double)>)>()
external int doesntMatter(int x, int y);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 90, 12),
    ]);
  }

  test_NativeVarArgsTooMany() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64, VarArgs<(Int32, Double)>)>()
external int doesntMatter(int x, int y, double z, int superfluous);
''', [
      error(FfiCode.FFI_NATIVE_UNEXPECTED_NUMBER_OF_PARAMETERS, 90, 12),
    ]);
  }

  test_NativeVoidReturn() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<Handle Function(Uint32, Uint32, Handle)>()
external void voidReturn(int width, int height, Object outImage);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 84, 10),
    ]);
  }

  test_NativeWrongFfiParameter() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(Double)>()
external int wrongFfiParameter(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 67, 17),
    ]);
  }

  test_NativeWrongFfiReturnType() async {
    await assertErrorsInCode(r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>()
external double wrongFfiReturnType(int v);
''', [
      error(FfiCode.MUST_BE_A_SUBTYPE, 70, 18),
    ]);
  }
}
