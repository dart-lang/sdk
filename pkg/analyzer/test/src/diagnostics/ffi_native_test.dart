// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

void main() => print(Native.addressOf(() => 3));
''',
      [error(diag.argumentMustBeNative, 58, 7)],
    );
  }

  test_invalid_MismatchedInferredType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
external Pointer<IntPtr> global;

void main() => print(Native.addressOf<Pointer<Double>>(global));
''',
      [error(diag.mustBeASubtype, 85, 41)],
    );
  }

  test_invalid_MismatchingType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

void main() {
  print(Native.addressOf<NativeFunction<Int8 Function()>>(foo));
}
''',
      [error(diag.mustBeASubtype, 91, 54)],
    );
  }

  test_invalid_MissingType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

void main() {
  print(Native.addressOf(foo));
}
''',
      [
        error(
          diag.mustBeANativeFunctionType,
          91,
          21,
          messageContains: [
            "The type 'NativeType' given to 'Native.addressOf' must be",
          ],
        ),
      ],
    );
  }

  test_invalid_MissingType2() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
external void foo();

void main() {
  print(Native.addressOf(foo));
}
''',
      [
        error(
          diag.mustBeANativeFunctionType,
          74,
          21,
          messageContains: [
            "The type 'NativeType' given to 'Native.addressOf' must be",
          ],
        ),
      ],
    );
  }

  test_invalid_MissingType3() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
external Pointer<IntPtr> global;

void main() => print(Native.addressOf(global));
''',
      [error(diag.mustBeASubtype, 85, 24)],
    );
  }

  test_invalid_NotAConstant() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();
@Native<Void Function()>()
external void bar();

void entry(bool condition) {
  print(Native.addressOf(condition ? foo : bar));
}
''',
      [error(diag.argumentMustBeNative, 171, 21)],
    );
  }

  test_invalid_NotAPreciseType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

void main() => print(Native.addressOf<NativeFunction>(foo));
''',
      [error(diag.mustBeASubtype, 90, 37)],
    );
  }

  test_invalid_NotAPreciseType2() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
external void foo();

void main() => print(Native.addressOf<NativeFunction>(foo));
''',
      [error(diag.mustBeASubtype, 73, 37)],
    );
  }

  test_invalid_String() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

void main() => print(Native.addressOf('malloc'));
''',
      [error(diag.argumentMustBeNative, 58, 8)],
    );
  }

  test_valid() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

@Native()
external void foo2();

@Native()
external Pointer<IntPtr> global;

void main() {
  print(Native.addressOf<NativeFunction<Void Function()>>(foo));
  print(Native.addressOf<NativeFunction<Void Function()>>(foo2));
  print(Native.addressOf<Pointer<IntPtr>>(global));
}
''');
  }
}

@reflectiveTest
class DefaultAssetTest extends PubPackageResolutionTest {
  test_invalid_duplicate() async {
    await assertErrorsInCode(
      r'''
@DefaultAsset('foo')
@DefaultAsset('bar')
library;

import 'dart:ffi';
''',
      [error(diag.ffiNativeInvalidDuplicateDefaultAsset, 22, 12)],
    );
  }

  test_invalid_duplicateFromConst() async {
    await assertErrorsInCode(
      r'''
@DefaultAsset('bar')
@defaults
library;

import 'dart:ffi';

const defaults = DefaultAsset('foo');
''',
      [error(diag.ffiNativeInvalidDuplicateDefaultAsset, 22, 8)],
    );
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
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native
external int foo();
''',
      [error(diag.noAnnotationConstructorArguments, 20, 7)],
    );
  }

  test_annotation_FfiNative_noTypeArguments() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
external int foo();
''',
      [error(diag.nativeFunctionMissingType, 43, 3)],
    );
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
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class K {
  @Native<Void Function(Double)>(symbol: 'DoesntMatter')
  external void doesntMatter(double x);
}
''',
      [error(diag.ffiNativeUnexpectedNumberOfParametersWithReceiver, 102, 12)],
    );
  }

  test_FfiNativeLeafMustNotReturnHandle() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Handle Function()>(symbol: 'DoesntMatter', isLeaf:true)
external Object doesntMatter();
''',
      [error(diag.leafCallMustNotReturnHandle, 99, 12)],
    );
  }

  test_FfiNativeLeafMustNotTakeHandles() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
''',
      [error(diag.leafCallMustNotTakeHandle, 101, 12)],
    );
  }

  test_FfiNativeNonFfiParameter() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<IntPtr Function(int)>(symbol: 'doesntmatter')
external int nonFfiParameter(int v);
''',
      [
        error(
          diag.mustBeANativeFunctionType,
          86,
          15,
          messageContains: [
            "The type 'IntPtr Function(int)' given to 'Native' must be",
          ],
        ),
      ],
    );
  }

  test_FfiNativeNonFfiReturnType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<double Function(IntPtr)>(symbol: 'doesntmatter')
external double nonFfiReturnType(int v);
''',
      [error(diag.mustBeANativeFunctionType, 92, 16)],
    );
  }

  test_FfiNativePointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Pointer)>(symbol: 'free')
external void posixFree(Pointer pointer);
''');
  }

  test_FfiNativeTooFewParameters() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Void Function(Double)>(symbol: 'DoesntMatter')
external void doesntMatter(double x, double y);
''',
      [error(diag.ffiNativeUnexpectedNumberOfParameters, 88, 12)],
    );
  }

  test_FfiNativeTooManyParameters() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Void Function(Double, Double)>(symbol: 'DoesntMatter')
external void doesntMatter(double x);
''',
      [error(diag.ffiNativeUnexpectedNumberOfParameters, 96, 12)],
    );
  }

  test_FfiNativeVoidReturn() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Handle Function(Uint32, Uint32, Handle)>(symbol: 'doesntmatter')
external void voidReturn(int width, int height, Object outImage);
''',
      [error(diag.mustBeASubtype, 106, 10)],
    );
  }

  test_FfiNativeWrongFfiParameter() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<IntPtr Function(Double)>(symbol: 'doesntmatter')
external int wrongFfiParameter(int v);
''',
      [error(diag.mustBeASubtype, 89, 17)],
    );
  }

  test_FfiNativeWrongFfiReturnType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>(symbol: 'doesntmatter')
external double wrongFfiReturnType(int v);
''',
      [error(diag.mustBeASubtype, 92, 18)],
    );
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
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
@Array(0)
external Array<IntPtr> field;
''',
      [error(diag.nonPositiveArrayDimension, 37, 1)],
    );
  }

  test_Array_InvalidDimensionCount() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
@Array(10, 20)
external Array<IntPtr> field;
''',
      [error(diag.sizeAnnotationDimensions, 30, 14)],
    );
  }

  test_Array_MissingAnnotation() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
external Array<IntPtr> field;
''',
      [error(diag.missingSizeAnnotationCarray, 53, 5)],
    );
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
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>()
external int field;
''',
      [error(diag.nativeFieldInvalidType, 67, 5)],
    );
  }

  test_InvalidInstanceMember() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

class Foo {
  @Native<IntPtr>()
  external int field;
}
''',
      [error(diag.nativeFieldNotStatic, 67, 5)],
    );
  }

  test_InvalidNotExternal() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<IntPtr>()
int field;
''',
      [
        error(diag.notInitializedNonNullableVariable, 42, 5),
        error(diag.ffiNativeMustBeExternal, 42, 5),
      ],
    );
  }

  test_MismatchingFunctionType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<NativeFunction<Double Function()>>()
external int Function() field;
''',
      [error(diag.mustBeASubtype, 89, 5)],
    );
  }

  test_MismatchingType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<Double>()
external int field;
''',
      [error(diag.mustBeASubtype, 51, 5)],
    );
  }

  test_MissingType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
external int invalid;

@Native()
external Pointer<IntPtr> valid;
''',
      [error(diag.nativeFieldMissingType, 43, 7)],
    );
  }

  test_Unsupported_Function() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<NativeFunction<Void Function()>>()
external void Function() field;
''',
      [error(diag.nativeFieldInvalidType, 88, 5)],
    );
  }

  test_Unsupported_Handle() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<Handle>()
external Object field;
''',
      [error(diag.nativeFieldInvalidType, 54, 5)],
    );
  }
}

@reflectiveTest
class NativeTest extends PubPackageResolutionTest {
  test_annotation_InvalidFieldType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native<IntPtr>()
external int foo();
''',
      [
        error(
          diag.mustBeANativeFunctionType,
          51,
          3,
          messageContains: ["The type 'IntPtr' given to 'Native' must be"],
        ),
      ],
    );
  }

  test_annotation_MissingType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native()
external int foo();
''',
      [error(diag.nativeFunctionMissingType, 43, 3)],
    );
  }

  test_annotation_MissingTypeConst() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

const a = Native();

@a
external int foo();
''',
      [error(diag.nativeFunctionMissingType, 57, 3)],
    );
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
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

@Native
external int foo();
''',
      [error(diag.noAnnotationConstructorArguments, 20, 7)],
    );
  }

  test_InferPointerReturnNoParameters() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external Pointer foo();
''');
  }

  test_InferPointerReturnPointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external Pointer foo(Pointer x);
''');
  }

  test_InferPointerReturnStructParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external Pointer foo(MyStruct x);

final class MyStruct extends Struct {
  @Int8()
  external int value;
}
''');
  }

  test_InferPointerReturnUnionParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external Pointer foo(MyUnion x);

final class MyUnion extends Union {
  @Int8()
  external int a;
  @Int8()
  external int b;
}
''');
  }

  test_InferStructReturnNoParameters() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external MyStruct foo();

final class MyStruct extends Struct {
  @Int8()
  external int value;
}
''');
  }

  test_InferStructReturnPointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external MyStruct foo(Pointer x);

final class MyStruct extends Struct {
  @Int8()
  external int value;
}
''');
  }

  test_InferStructReturnStructParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external MyStruct foo(MyStruct x);

final class MyStruct extends Struct {
  @Int8()
  external int value;
}
''');
  }

  test_InferStructReturnUnionParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external MyStruct foo(MyUnion x);

final class MyStruct extends Struct {
  @Int8()
  external int value;
}

final class MyUnion extends Union {
  @Int8()
  external int a;
  @Int8()
  external int b;
}
''');
  }

  test_InferUnionReturnNoParameters() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external MyUnion foo();

final class MyUnion extends Union {
  @Int8()
  external int a;
  @Int8()
  external int b;
}
''');
  }

  test_InferUnionReturnPointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external MyUnion foo(Pointer x);

final class MyUnion extends Union {
  @Int8()
  external int a;
  @Int8()
  external int b;
}
''');
  }

  test_InferUnionReturnStructParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external MyUnion foo(MyStruct x);

final class MyStruct extends Struct {
  @Int8()
  external int value;
}

final class MyUnion extends Union {
  @Int8()
  external int a;
  @Int8()
  external int b;
}
''');
  }

  test_InferUnionReturnUnionParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external MyUnion foo(MyUnion x);

final class MyUnion extends Union {
  @Int8()
  external int a;
  @Int8()
  external int b;
}
''');
  }

  test_InferVoidReturnNoParameters() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external void foo();
''');
  }

  test_InferVoidReturnPointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external void foo(Pointer x);
''');
  }

  test_InferVoidReturnStructParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external void foo(MyStruct x);

final class MyStruct extends Struct {
  @Int8()
  external int value;
}
''');
  }

  test_InferVoidReturnUnionParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';

@Native()
external void foo(MyUnion x);

final class MyUnion extends Union {
  @Int8()
  external int a;
  @Int8()
  external int b;
}
''');
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
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Int32 Function(Int32)>()
@Native<Int32 Function(Int32)>(isLeaf: true)
external int foo(int v);
''',
      [error(diag.ffiNativeInvalidMultipleAnnotations, 53, 6)],
    );
  }

  test_NativeDuplicateAnnotationConst() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';

const duplicate = Native<Int32 Function(Int32)>(isLeaf: true);

@Native<Int32 Function(Int32)>()
@duplicate
external int foo(int v);
''',
      [error(diag.ffiNativeInvalidMultipleAnnotations, 118, 9)],
    );
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
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
class K {
  @Native<Void Function(Double)>()
  external void doesntMatter(double x);
}
''',
      [error(diag.ffiNativeUnexpectedNumberOfParametersWithReceiver, 80, 12)],
    );
  }

  test_NativeLeafMustNotReturnHandle() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Handle Function()>(isLeaf:true)
external Object doesntMatter();
''',
      [error(diag.leafCallMustNotReturnHandle, 75, 12)],
    );
  }

  test_NativeLeafMustNotReturnHandleConst() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
const annotation = Native<Handle Function()>(isLeaf:true);

@annotation
external Object doesntMatter();
''',
      [error(diag.leafCallMustNotReturnHandle, 107, 12)],
    );
  }

  test_NativeLeafMustNotTakeHandles() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
''',
      [error(diag.leafCallMustNotTakeHandle, 101, 12)],
    );
  }

  test_NativeLeafMustNotTakeHandlesConst() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
const annotation = Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true);

@annotation
external void doesntMatter(Object o);
''',
      [error(diag.leafCallMustNotTakeHandle, 133, 12)],
    );
  }

  test_NativeNonFfiParameter() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<IntPtr Function(int)>()
external int nonFfiParameter(int v);
''',
      [error(diag.mustBeANativeFunctionType, 64, 15)],
    );
  }

  test_NativeNonFfiReturnType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<double Function(IntPtr)>()
external double nonFfiReturnType(int v);
''',
      [error(diag.mustBeANativeFunctionType, 70, 16)],
    );
  }

  test_NativePointerParameter() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@Native<Void Function(Pointer)>()
external void free(Pointer pointer);
''');
  }

  test_NativeTooFewParameters() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Void Function(Double)>()
external void doesntMatter(double x, double y);
''',
      [error(diag.ffiNativeUnexpectedNumberOfParameters, 66, 12)],
    );
  }

  test_NativeTooManyParameters() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Void Function(Double, Double)>()
external void doesntMatter(double x);
''',
      [error(diag.ffiNativeUnexpectedNumberOfParameters, 74, 12)],
    );
  }

  test_NativeVarArgs() async {
    await assertNoErrorsInCode(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64, VarArgs<(Int32, Double)>)>()
external int doesntMatter(int x, int y, double z);
''');
  }

  test_NativeVarArgsTooFew() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Int8 Function(Int64, VarArgs<(Int32, Double)>)>()
external int doesntMatter(int x, int y);
''',
      [error(diag.ffiNativeUnexpectedNumberOfParameters, 90, 12)],
    );
  }

  test_NativeVarArgsTooMany() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Int8 Function(Int64, VarArgs<(Int32, Double)>)>()
external int doesntMatter(int x, int y, double z, int superfluous);
''',
      [error(diag.ffiNativeUnexpectedNumberOfParameters, 90, 12)],
    );
  }

  test_NativeVoidReturn() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<Handle Function(Uint32, Uint32, Handle)>()
external void voidReturn(int width, int height, Object outImage);
''',
      [error(diag.mustBeASubtype, 84, 10)],
    );
  }

  test_NativeWrongFfiParameter() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<IntPtr Function(Double)>()
external int wrongFfiParameter(int v);
''',
      [error(diag.mustBeASubtype, 67, 17)],
    );
  }

  test_NativeWrongFfiReturnType() async {
    await assertErrorsInCode(
      r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>()
external double wrongFfiReturnType(int v);
''',
      [error(diag.mustBeASubtype, 70, 18)],
    );
  }
}
