// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

void main() => print(Native.addressOf(() => 3));
//                                    ^^^^^^^
// [diag.argumentMustBeNative] Argument to 'Native.addressOf' must be annotated with @Native
''');
  }

  test_invalid_MismatchedInferredType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external Pointer<IntPtr> global;

void main() => print(Native.addressOf<Pointer<Double>>(global));
//                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Pointer<IntPtr>' must be a subtype of 'Pointer<Double>' for 'Native.addressOf'.
''');
  }

  test_invalid_MismatchingType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

void main() {
  print(Native.addressOf<NativeFunction<Int8 Function()>>(foo));
//      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Void Function()' must be a subtype of 'Int8 Function()' for 'Native.addressOf'.
}
''');
  }

  test_invalid_MissingType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

void main() {
  print(Native.addressOf(foo));
//      ^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'NativeType' given to 'Native.addressOf' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_invalid_MissingType2() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external void foo();

void main() {
  print(Native.addressOf(foo));
//      ^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'NativeType' given to 'Native.addressOf' must be a valid 'dart:ffi' native function type.
}
''');
  }

  test_invalid_MissingType3() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external Pointer<IntPtr> global;

void main() => print(Native.addressOf(global));
//                   ^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Pointer<IntPtr>' must be a subtype of 'NativeType' for 'Native.addressOf'.
''');
  }

  test_invalid_NotAConstant() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();
@Native<Void Function()>()
external void bar();

void entry(bool condition) {
  print(Native.addressOf(condition ? foo : bar));
//                       ^^^^^^^^^^^^^^^^^^^^^
// [diag.argumentMustBeNative] Argument to 'Native.addressOf' must be annotated with @Native
}
''');
  }

  test_invalid_NotAPreciseType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<Void Function()>()
external void foo();

void main() => print(Native.addressOf<NativeFunction>(foo));
//                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Void Function()' must be a subtype of 'Function' for 'Native.addressOf'.
''');
  }

  test_invalid_NotAPreciseType2() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external void foo();

void main() => print(Native.addressOf<NativeFunction>(foo));
//                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Void Function()' must be a subtype of 'Function' for 'Native.addressOf'.
''');
  }

  test_invalid_String() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

void main() => print(Native.addressOf('malloc'));
//                                    ^^^^^^^^
// [diag.argumentMustBeNative] Argument to 'Native.addressOf' must be annotated with @Native
''');
  }

  test_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
@DefaultAsset('foo')
@DefaultAsset('bar')
// [diag.ffiNativeInvalidDuplicateDefaultAsset][column 2][length 12] There may be at most one @DefaultAsset annotation on a library.
library;

import 'dart:ffi';
''');
  }

  test_invalid_duplicateFromConst() async {
    await resolveTestCodeWithDiagnostics(r'''
@DefaultAsset('bar')
@defaults
// [diag.ffiNativeInvalidDuplicateDefaultAsset][column 2][length 8] There may be at most one @DefaultAsset annotation on a library.
library;

import 'dart:ffi';

const defaults = DefaultAsset('foo');
''');
  }

  test_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
@DefaultAsset('bar')
library;

import 'dart:ffi';

@Native<Void Function()>()
external void foo();
''');
  }

  test_validFromConst() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

base class NativeFieldWrapperClass1 {}

base class Paragraph extends NativeFieldWrapperClass1 {
  @Native<Double Function(Pointer<Void>)>(symbol: 'Paragraph::ideographicBaseline', isLeaf: true)
  external double get ideographicBaseline;

  @Native<Void Function(Pointer<Void>, Double)>(symbol: 'Paragraph::ideographicBaseline', isLeaf: true)
  external set ideographicBaseline(double d);
}
''');
  }

  test_annotation_FfiNative_noArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native
// [diag.noAnnotationConstructorArguments][column 1][length 7] Annotation creation must have arguments.
external int foo();
''');
  }

  test_annotation_FfiNative_noTypeArguments() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external int foo();
//           ^^^
// [diag.nativeFunctionMissingType] The native type of this function couldn't be inferred so it must be specified in the annotation.
''');
  }

  test_FfiNativeCanUseHandles() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Handle Function(Handle)>(symbol: 'DoesntMatter')
external Object doesntMatter(Object);
''');
  }

  test_FfiNativeCanUseLeaf() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64)>(symbol: 'DoesntMatter', isLeaf:true)
external int doesntMatter(int x);
''');
  }

  test_FfiNativeInstanceMethodsMustHaveReceiver() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class K {
  @Native<Void Function(Double)>(symbol: 'DoesntMatter')
  external void doesntMatter(double x);
//              ^^^^^^^^^^^^
// [diag.ffiNativeUnexpectedNumberOfParametersWithReceiver] Unexpected number of Native annotation parameters. Expected 2 but has 1. Native instance method annotation must have receiver as first argument.
}
''');
  }

  test_FfiNativeLeafMustNotReturnHandle() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Handle Function()>(symbol: 'DoesntMatter', isLeaf:true)
external Object doesntMatter();
//              ^^^^^^^^^^^^
// [diag.leafCallMustNotReturnHandle] FFI leaf call can't return a 'Handle'.
''');
  }

  test_FfiNativeLeafMustNotTakeHandles() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
//            ^^^^^^^^^^^^
// [diag.leafCallMustNotTakeHandle] FFI leaf call can't take arguments of type 'Handle'.
''');
  }

  test_FfiNativeNonFfiParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<IntPtr Function(int)>(symbol: 'doesntmatter')
external int nonFfiParameter(int v);
//           ^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'IntPtr Function(int)' given to 'Native' must be a valid 'dart:ffi' native function type.
''');
  }

  test_FfiNativeNonFfiReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<double Function(IntPtr)>(symbol: 'doesntmatter')
external double nonFfiReturnType(int v);
//              ^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'double Function(IntPtr)' given to 'Native' must be a valid 'dart:ffi' native function type.
''');
  }

  test_FfiNativeOnExtension_valid() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

extension on int {
  @Native<Bool Function(Int64, Int64)>(symbol: 'x')
  external bool f(int m);
}

void g() {
  0.f(0);
}
''');
  }

  test_FfiNativeOnExtension_wrongNumberOfParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

extension on int {
  @Native<Bool Function(Int64)>(symbol: 'x')
  external bool f(int m);
//              ^
// [diag.ffiNativeUnexpectedNumberOfParameters] Unexpected number of Native annotation parameters. Expected 2 but has 1.
}

void g() {
  0.f(0);
}
''');
  }

  test_FfiNativeOnExtension_wrongReceiverType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

extension on double {
  @Native<Bool Function(Int64, Int64)>(symbol: 'Dart_PostInteger')
  external bool postInteger(int message);
//              ^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Bool Function(Int64, Int64)' must be a subtype of 'bool Function(double, int)' for 'Native'.
}

void f() {
  0.0.postInteger(0);
}
''');
  }

  test_FfiNativeOnExtensionType_wrongReceiverType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

extension type NativeSendPort(int id) {
  @Native<Bool Function(Int64, Int64)>(symbol: 'Dart_PostInteger')
  external bool postInteger(int message);
//              ^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Bool Function(Int64, Int64)' must be a subtype of 'bool Function(NativeSendPort, int)' for 'Native'.
}
''');
  }

  test_FfiNativeOnExtensionType_wrongRepresentationType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

extension type InvalidNativeSendPort._(double id) {
  @Native<Bool Function(Int64, Int64)>(symbol: 'Dart_PostInteger')
  external bool postInteger(int message);
//              ^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Bool Function(Int64, Int64)' must be a subtype of 'bool Function(InvalidNativeSendPort, int)' for 'Native'.
}
''');
  }

  test_FfiNativePointerParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Void Function(Pointer)>(symbol: 'free')
external void posixFree(Pointer pointer);
''');
  }

  test_FfiNativeTooFewParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Void Function(Double)>(symbol: 'DoesntMatter')
external void doesntMatter(double x, double y);
//            ^^^^^^^^^^^^
// [diag.ffiNativeUnexpectedNumberOfParameters] Unexpected number of Native annotation parameters. Expected 1 but has 2.
''');
  }

  test_FfiNativeTooManyParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Void Function(Double, Double)>(symbol: 'DoesntMatter')
external void doesntMatter(double x);
//            ^^^^^^^^^^^^
// [diag.ffiNativeUnexpectedNumberOfParameters] Unexpected number of Native annotation parameters. Expected 2 but has 1.
''');
  }

  test_FfiNativeVoidReturn() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Handle Function(Uint32, Uint32, Handle)>(symbol: 'doesntmatter')
external void voidReturn(int width, int height, Object outImage);
//            ^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Handle Function(Uint32, Uint32, Handle)' must be a subtype of 'void Function(int, int, Object)' for 'Native'.
''');
  }

  test_FfiNativeWrongFfiParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<IntPtr Function(Double)>(symbol: 'doesntmatter')
external int wrongFfiParameter(int v);
//           ^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'IntPtr Function(Double)' must be a subtype of 'int Function(int)' for 'Native'.
''');
  }

  test_FfiNativeWrongFfiReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>(symbol: 'doesntmatter')
external double wrongFfiReturnType(int v);
//              ^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'IntPtr Function(IntPtr)' must be a subtype of 'double Function(int)' for 'Native'.
''');
  }
}

@reflectiveTest
class NativeFieldTest extends PubPackageResolutionTest {
  test_AbiSpecific() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<Int>()
external int foo;
''');
  }

  test_Accessors() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<IntPtr>()
external int get foo;

@Native<IntPtr>()
external set foo(int value);
''');
  }

  test_Array_InvalidDimension() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
@Array(0)
//     ^
// [diag.nonPositiveArrayDimension] Array dimensions must be positive numbers.
external Array<IntPtr> field;
''');
  }

  test_Array_InvalidDimensionCount() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
@Array(10, 20)
// [diag.sizeAnnotationDimensions][column 1][length 14] 'Array's must have an 'Array' annotation that matches the dimensions.
external Array<IntPtr> field;
''');
  }

  test_Array_MissingAnnotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external Array<IntPtr> field;
//                     ^^^^^
// [diag.missingSizeAnnotationCarray] Fields of type 'Array' must have exactly one 'Array' annotation.
''');
  }

  test_Array_Valid() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>()
external int field;
//           ^^^^^
// [diag.nativeFieldInvalidType] 'IntPtr Function(IntPtr)' is an unsupported type for native fields. Native fields only support pointers, arrays or numeric and compound types.
''');
  }

  test_InvalidInstanceMember() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

class Foo {
  @Native<IntPtr>()
  external int field;
//             ^^^^^
// [diag.nativeFieldNotStatic] Native fields must be static.
}
''');
  }

  test_InvalidNotExternal() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<IntPtr>()
int field;
//  ^^^^^
// [diag.notInitializedNonNullableVariable] The non-nullable variable 'field' must be initialized.
// [diag.ffiNativeMustBeExternal] Native functions must be declared external.
''');
  }

  test_MismatchingFunctionType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<NativeFunction<Double Function()>>()
external int Function() field;
//                      ^^^^^
// [diag.mustBeASubtype] The type 'int Function()' must be a subtype of 'NativeFunction<Double Function()>' for 'Native'.
''');
  }

  test_MismatchingType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<Double>()
external int field;
//           ^^^^^
// [diag.mustBeASubtype] The type 'int' must be a subtype of 'Double' for 'Native'.
''');
  }

  test_MissingType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external int invalid;
//           ^^^^^^^
// [diag.nativeFieldMissingType] The native type of this field could not be inferred and must be specified in the annotation.

@Native()
external Pointer<IntPtr> valid;
''');
  }

  test_Unsupported_Function() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<NativeFunction<Void Function()>>()
external void Function() field;
//                       ^^^^^
// [diag.nativeFieldInvalidType] 'NativeFunction<Void Function()>' is an unsupported type for native fields. Native fields only support pointers, arrays or numeric and compound types.
''');
  }

  test_Unsupported_Handle() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<Handle>()
external Object field;
//              ^^^^^
// [diag.nativeFieldInvalidType] 'Handle' is an unsupported type for native fields. Native fields only support pointers, arrays or numeric and compound types.
''');
  }
}

@reflectiveTest
class NativeTest extends PubPackageResolutionTest {
  test_annotation_InvalidFieldType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native<IntPtr>()
external int foo();
//           ^^^
// [diag.mustBeANativeFunctionType] The type 'IntPtr' given to 'Native' must be a valid 'dart:ffi' native function type.
''');
  }

  test_annotation_MissingType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external int foo();
//           ^^^
// [diag.nativeFunctionMissingType] The native type of this function couldn't be inferred so it must be specified in the annotation.
''');
  }

  test_annotation_MissingTypeConst() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

const a = Native();

@a
external int foo();
//           ^^^
// [diag.nativeFunctionMissingType] The native type of this function couldn't be inferred so it must be specified in the annotation.
''');
  }

  test_annotation_Native_getters() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native
// [diag.noAnnotationConstructorArguments][column 1][length 7] Annotation creation must have arguments.
external int foo();
''');
  }

  test_InferPointerReturnNoParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external Pointer foo();
''');
  }

  test_InferPointerReturnPointerParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external Pointer foo(Pointer x);
''');
  }

  test_InferPointerReturnStructParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external void foo();
''');
  }

  test_InferVoidReturnPointerParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

@Native()
external void foo(Pointer x);
''');
  }

  test_InferVoidReturnStructParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
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
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Handle Function(Handle)>()
external Object doesntMatter(Object);
''');
  }

  test_NativeCanUseLeaf() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64)>(isLeaf:true)
external int doesntMatter(int x);
''');
  }

  test_NativeDuplicateAnnotation() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Int32 Function(Int32)>()
@Native<Int32 Function(Int32)>(isLeaf: true)
// [diag.ffiNativeInvalidMultipleAnnotations][column 2][length 6] Native functions and fields must have exactly one `@Native` annotation.
external int foo(int v);
''');
  }

  test_NativeDuplicateAnnotationConst() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

const duplicate = Native<Int32 Function(Int32)>(isLeaf: true);

@Native<Int32 Function(Int32)>()
@duplicate
// [diag.ffiNativeInvalidMultipleAnnotations][column 2][length 9] Native functions and fields must have exactly one `@Native` annotation.
external int foo(int v);
''');
  }

  test_NativeFromConst() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';

const annotation = Native<Int32 Function(Int32)>();

@annotation
external int wrongFfiReturnType(int v);
''');
  }

  test_NativeInstanceMethodsMustHaveReceiver() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
class K {
  @Native<Void Function(Double)>()
  external void doesntMatter(double x);
//              ^^^^^^^^^^^^
// [diag.ffiNativeUnexpectedNumberOfParametersWithReceiver] Unexpected number of Native annotation parameters. Expected 2 but has 1. Native instance method annotation must have receiver as first argument.
}
''');
  }

  test_NativeLeafMustNotReturnHandle() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Handle Function()>(isLeaf:true)
external Object doesntMatter();
//              ^^^^^^^^^^^^
// [diag.leafCallMustNotReturnHandle] FFI leaf call can't return a 'Handle'.
''');
  }

  test_NativeLeafMustNotReturnHandleConst() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
const annotation = Native<Handle Function()>(isLeaf:true);

@annotation
external Object doesntMatter();
//              ^^^^^^^^^^^^
// [diag.leafCallMustNotReturnHandle] FFI leaf call can't return a 'Handle'.
''');
  }

  test_NativeLeafMustNotTakeHandles() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true)
external void doesntMatter(Object o);
//            ^^^^^^^^^^^^
// [diag.leafCallMustNotTakeHandle] FFI leaf call can't take arguments of type 'Handle'.
''');
  }

  test_NativeLeafMustNotTakeHandlesConst() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
const annotation = Native<Void Function(Handle)>(symbol: 'DoesntMatter', isLeaf:true);

@annotation
external void doesntMatter(Object o);
//            ^^^^^^^^^^^^
// [diag.leafCallMustNotTakeHandle] FFI leaf call can't take arguments of type 'Handle'.
''');
  }

  test_NativeNonFfiParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<IntPtr Function(int)>()
external int nonFfiParameter(int v);
//           ^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'IntPtr Function(int)' given to 'Native' must be a valid 'dart:ffi' native function type.
''');
  }

  test_NativeNonFfiReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<double Function(IntPtr)>()
external double nonFfiReturnType(int v);
//              ^^^^^^^^^^^^^^^^
// [diag.mustBeANativeFunctionType] The type 'double Function(IntPtr)' given to 'Native' must be a valid 'dart:ffi' native function type.
''');
  }

  test_NativePointerParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Void Function(Pointer)>()
external void free(Pointer pointer);
''');
  }

  test_NativeTooFewParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Void Function(Double)>()
external void doesntMatter(double x, double y);
//            ^^^^^^^^^^^^
// [diag.ffiNativeUnexpectedNumberOfParameters] Unexpected number of Native annotation parameters. Expected 1 but has 2.
''');
  }

  test_NativeTooManyParameters() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Void Function(Double, Double)>()
external void doesntMatter(double x);
//            ^^^^^^^^^^^^
// [diag.ffiNativeUnexpectedNumberOfParameters] Unexpected number of Native annotation parameters. Expected 2 but has 1.
''');
  }

  test_NativeVarArgs() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64, VarArgs<(Int32, Double)>)>()
external int doesntMatter(int x, int y, double z);
''');
  }

  test_NativeVarArgsTooFew() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64, VarArgs<(Int32, Double)>)>()
external int doesntMatter(int x, int y);
//           ^^^^^^^^^^^^
// [diag.ffiNativeUnexpectedNumberOfParameters] Unexpected number of Native annotation parameters. Expected 3 but has 2.
''');
  }

  test_NativeVarArgsTooMany() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Int8 Function(Int64, VarArgs<(Int32, Double)>)>()
external int doesntMatter(int x, int y, double z, int superfluous);
//           ^^^^^^^^^^^^
// [diag.ffiNativeUnexpectedNumberOfParameters] Unexpected number of Native annotation parameters. Expected 3 but has 4.
''');
  }

  test_NativeVoidReturn() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<Handle Function(Uint32, Uint32, Handle)>()
external void voidReturn(int width, int height, Object outImage);
//            ^^^^^^^^^^
// [diag.mustBeASubtype] The type 'Handle Function(Uint32, Uint32, Handle)' must be a subtype of 'void Function(int, int, Object)' for 'Native'.
''');
  }

  test_NativeWrongFfiParameter() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<IntPtr Function(Double)>()
external int wrongFfiParameter(int v);
//           ^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'IntPtr Function(Double)' must be a subtype of 'int Function(int)' for 'Native'.
''');
  }

  test_NativeWrongFfiReturnType() async {
    await resolveTestCodeWithDiagnostics(r'''
import 'dart:ffi';
@Native<IntPtr Function(IntPtr)>()
external double wrongFfiReturnType(int v);
//              ^^^^^^^^^^^^^^^^^^
// [diag.mustBeASubtype] The type 'IntPtr Function(IntPtr)' must be a subtype of 'double Function(int)' for 'Native'.
''');
  }
}
