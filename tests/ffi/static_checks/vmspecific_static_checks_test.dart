// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi extra checks
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

import 'dart:ffi';

import "package:ffi/ffi.dart";

void main() {
  testGetGeneric();
  testGetGeneric2();
  testGetVoid();
  testGetNativeFunction();
  testGetNativeType();
  testGetTypeMismatch();
  testSetGeneric();
  testSetGeneric2();
  testSetVoid();
  testSetNativeFunction();
  testSetNativeType();
  testSetTypeMismatch();
  testAsFunctionGeneric();
  testAsFunctionGeneric2();
  testAsFunctionWrongNativeFunctionSignature();
  testAsFunctionTypeMismatch();
  testFromFunctionGeneric();
  testFromFunctionGeneric2();
  testFromFunctionWrongNativeFunctionSignature();
  testFromFunctionTypeMismatch();
  testFromFunctionClosure();
  testFromFunctionTearOff();
  testFromFunctionAbstract();
  testFromFunctionFunctionExceptionValueMustBeConst();
  testNativeCallableListenerGeneric();
  testNativeCallableListenerGeneric2();
  testNativeCallableListenerWrongNativeFunctionSignature();
  testNativeCallableListenerTypeMismatch();
  testNativeCallableListenerAbstract();
  testNativeCallableListenerMustReturnVoid();
  testNativeCallableIsolateLocalGeneric();
  testNativeCallableIsolateLocalGeneric2();
  testNativeCallableIsolateLocalWrongNativeFunctionSignature();
  testNativeCallableIsolateLocalTypeMismatch();
  testNativeCallableIsolateLocalTearOff();
  testNativeCallableIsolateLocalAbstract();
  testNativeCallableIsolateLocalFunctionExceptionValueMustBeConst();
  testLookupFunctionGeneric();
  testLookupFunctionGeneric2();
  testLookupFunctionWrongNativeFunctionSignature();
  testLookupFunctionTypeMismatch();
  testLookupFunctionPointervoid();
  testLookupFunctionPointerNFdyn();
  testHandleVariance();
  testEmptyStructLookupFunctionArgument();
  testEmptyStructLookupFunctionReturn();
  testEmptyStructAsFunctionArgument();
  testEmptyStructAsFunctionReturn();
  testEmptyStructFromFunctionArgument();
  testEmptyStructFromFunctionReturn();
  testAllocateGeneric();
  testAllocateInvalidType();
  testCreateInvalidType();
  testRefStruct();
  testSizeOfGeneric();
  testSizeOfInvalidType();
  testLookupFunctionIsLeafMustBeConst();
  testAsFunctionIsLeafMustBeConst();
  testLookupFunctionTakesHandle();
  testAsFunctionTakesHandle();
  testLookupFunctionReturnsHandle();
  testAsFunctionReturnsHandle();
  testReturnVoidNotVoid();
}

typedef Int8UnOp = Int8 Function(Int8);
typedef IntUnOp = int Function(int);

void testGetGeneric() {
  int generic(Pointer p) {
    int result = -1;
    result = p.value;
    //         ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
    // [cfe] The getter 'value' isn't defined for the type 'Pointer<NativeType>'.
    return result;
  }

  Pointer<Int8> p = calloc();
  p.value = 123;
  Pointer loseType = p;
  generic(loseType);
  calloc.free(p);
}

void testGetGeneric2() {
  T? generic<T extends Object>() {
    Pointer<Int8> p = calloc();
    p.value = 123;
    T? result;
    result = p.value;
    //       ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //         ^
    // [cfe] A value of type 'int' can't be assigned to a variable of type 'T?'.
    calloc.free(p);
    return result;
  }

  generic<int>();
}

void testGetVoid() {
  Pointer<IntPtr> p1 = calloc();
  Pointer<Void> p2 = p1.cast();

  p2.value;
  // ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'value' isn't defined for the type 'Pointer<Void>'.

  calloc.free(p1);
}

void testGetNativeFunction() {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = p.value;
  //            ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'value' isn't defined for the type 'Pointer<NativeFunction<Int8 Function(Int8)>>'.
}

void testGetNativeType() {
  // Is it possible to obtain a Pointer<NativeType> at all?
}

void testGetTypeMismatch() {
  Pointer<Pointer<Int16>> p = calloc();
  Pointer<Int16> typedNull = nullptr;
  p.value = typedNull;

  // this fails to compile due to type mismatch
  Pointer<Int8> p2 = p.value;
  //                 ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                   ^
  // [cfe] A value of type 'Pointer<Int16>' can't be assigned to a variable of type 'Pointer<Int8>'.

  calloc.free(p);
}

void testSetGeneric() {
  void generic(Pointer p) {
    p.value = 123;
    //^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
    // [cfe] The setter 'value' isn't defined for the type 'Pointer<NativeType>'.
  }

  Pointer<Int8> p = calloc();
  p.value = 123;
  Pointer loseType = p;
  generic(loseType);
  calloc.free(p);
}

void testSetGeneric2() {
  void generic<T extends Object>(T arg) {
    Pointer<Int8> p = calloc();
    p.value = arg;
    //        ^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'T' can't be assigned to a variable of type 'int'.
    calloc.free(p);
  }

  generic<int>(123);
}

void testSetVoid() {
  Pointer<IntPtr> p1 = calloc();
  Pointer<Void> p2 = p1.cast();

  p2.value = 1234;
  // ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'value' isn't defined for the type 'Pointer<Void>'.

  calloc.free(p1);
}

void testSetNativeFunction() {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = (a) => a + 1;
  p.value = f;
  //^^^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'value' isn't defined for the type 'Pointer<NativeFunction<Int8 Function(Int8)>>'.
}

void testSetNativeType() {
  // Is it possible to obtain a Pointer<NativeType> at all?
}

void testSetTypeMismatch() {
  // the pointer to pointer types must match up
  Pointer<Int8> pHelper = calloc();
  pHelper.value = 123;

  Pointer<Pointer<Int16>> p = calloc();

  // this fails to compile due to type mismatch
  p.value = pHelper;
  //        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  // [cfe] A value of type 'Pointer<Int8>' can't be assigned to a variable of type 'Pointer<Int16>'.

  calloc.free(pHelper);
  calloc.free(p);
}

void testAsFunctionGeneric() {
  T generic<T extends Function>(T defaultFunction) {
    Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
    T f = defaultFunction;
    f = p.asFunction<T>();
    //    ^
    // [cfe] Expected type 'T' to be 'int Function(int)', which is the Dart type corresponding to 'NativeFunction<Int8 Function(Int8)>'.
    //               ^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
    return f;
  }

  generic<IntUnOp>((int a) => a + 1);
}

void testAsFunctionGeneric2() {
  generic(Pointer<NativeFunction> p) {
    Function f = () => "dummy";
    f = p.asFunction<IntUnOp>();
    //    ^
    // [cfe] Expected type 'NativeFunction<Function>' to be a valid and instantiated subtype of 'NativeType'.
    //               ^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER
    return f;
  }

  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  generic(p);
}

void testAsFunctionWrongNativeFunctionSignature() {
  Pointer<NativeFunction<IntUnOp>> p;
  Function f = p.asFunction<IntUnOp>();
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.NOT_ASSIGNED_POTENTIALLY_NON_NULLABLE_LOCAL_VARIABLE
  // [cfe] Non-nullable variable 'p' must be assigned before it can be used.
  //             ^
  // [cfe] Expected type 'NativeFunction<int Function(int)>' to be a valid and instantiated subtype of 'NativeType'.
  //                        ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER
}

typedef IntBinOp = int Function(int, int);

void testAsFunctionTypeMismatch() {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntBinOp f = p.asFunction();
  //           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  //             ^
  // [cfe] Expected type 'int Function(int, int)' to be 'int Function(int)', which is the Dart type corresponding to 'NativeFunction<Int8 Function(Int8)>'.
}

void testFunctionNotFunctionType() {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  Function f = p.asFunction();
  //           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
  //             ^
  // [cfe] Expected type 'Function' to be 'int Function(int)', which is the Dart type corresponding to 'NativeFunction<Int8 Function(Int8)>'.
}

typedef NativeDoubleUnOp = Double Function(Double);
typedef DoubleUnOp = double Function(double);

double myTimesThree(double d) => d * 3;

int myTimesFour(int i) => i * 4;

void testFromFunctionGeneric() {
  Pointer<NativeFunction> generic<T extends Function>(T f) {
    Pointer<NativeFunction<NativeDoubleUnOp>> result = nullptr;
    result = Pointer.fromFunction(f);
    //                            ^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
    // [cfe] fromFunction expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.
    return result;
  }

  generic(myTimesThree);
}

void testFromFunctionGeneric2() {
  Pointer<NativeFunction<T>> generic<T extends Function>() {
    Pointer<NativeFunction<T>> result = nullptr;
    result = Pointer.fromFunction(myTimesThree);
    //               ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
    // [cfe] Expected type 'NativeFunction<T>' to be a valid and instantiated subtype of 'NativeType'.
    return result;
  }

  generic<NativeDoubleUnOp>();
}

void testFromFunctionWrongNativeFunctionSignature() {
  Pointer.fromFunction<IntUnOp>(myTimesFour);
  //      ^
  // [cfe] Expected type 'NativeFunction<int Function(int)>' to be a valid and instantiated subtype of 'NativeType'.
  //                   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
}

void testFromFunctionTypeMismatch() {
  Pointer<NativeFunction<NativeDoubleUnOp>> p;
  p = Pointer.fromFunction(myTimesFour);
  //          ^
  // [cfe] Expected type 'int Function(int)' to be 'double Function(double)', which is the Dart type corresponding to 'NativeFunction<Double Function(Double)>'.
  //                       ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
}

void testFromFunctionClosure() {
  DoubleUnOp someClosure = (double z) => z / 27.0;
  Pointer<NativeFunction<NativeDoubleUnOp>> p;
  p = Pointer.fromFunction(someClosure);
  //          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_EXCEPTION_VALUE
  //                       ^
  // [cfe] fromFunction expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.
}

class X {
  double tearoff(double d) => d / 27.0;
}

void testFromFunctionTearOff() {
  DoubleUnOp fld = X().tearoff;
  Pointer<NativeFunction<NativeDoubleUnOp>> p;
  p = Pointer.fromFunction(fld);
  //          ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_EXCEPTION_VALUE
  //                       ^
  // [cfe] fromFunction expects a static function as parameter. dart:ffi only supports calling static Dart functions from native code. Closures and tear-offs are not supported because they can capture context.
}

void testFromFunctionAbstract() {
  Pointer.fromFunction<Function>(testFromFunctionAbstract);
  //      ^
  // [cfe] Expected type 'NativeFunction<Function>' to be a valid and instantiated subtype of 'NativeType'.
  //                   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
}

void testFromFunctionFunctionExceptionValueMustBeConst() {
  final notAConst = 1.1;
  Pointer<NativeFunction<NativeDoubleUnOp>> p;
  p = Pointer.fromFunction(myTimesThree, notAConst);
  //          ^
  // [cfe] Exceptional return value must be a constant.
  //                                     ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_MUST_BE_A_CONSTANT
}

typedef NativeVoidFunc = Void Function();
typedef VoidFunc = void Function();

void myVoidFunc() {
  print("Hello World");
}

void myVoidFunc2(int x) {
  print("x = $x");
}

void testNativeCallableListenerGeneric() {
  NativeCallable? generic<T extends Function>(T f) {
    NativeCallable<NativeVoidFunc>? result;
    result = NativeCallable.listener(f);
    //                      ^
    // [cfe] Expected type 'T' to be 'void Function()', which is the Dart type corresponding to 'NativeFunction<Void Function()>'.
    //                               ^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
    return result;
  }

  generic(myVoidFunc);
}

void testNativeCallableListenerGeneric2() {
  NativeCallable<T>? generic<T extends Function>() {
    NativeCallable<T>? result;
    result = NativeCallable.listener(myVoidFunc);
    //       ^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
    //                      ^
    // [cfe] Expected type 'NativeFunction<T>' to be a valid and instantiated subtype of 'NativeType'.
    return result;
  }

  generic<NativeVoidFunc>();
}

// dart format off

void testNativeCallableListenerWrongNativeFunctionSignature() {
  /**/ NativeCallable<NativeVoidFunc>.listener(myVoidFunc2);
  //   ^
  // [cfe] Expected type 'void Function(int)' to be 'void Function()', which is the Dart type corresponding to 'NativeFunction<Void Function()>'.
  //                                           ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
}

void testNativeCallableListenerTypeMismatch() {
  NativeCallable<NativeVoidFunc> p;
  p = NativeCallable.listener(myVoidFunc2);
  //                 ^
  // [cfe] Expected type 'void Function(int)' to be 'void Function()', which is the Dart type corresponding to 'NativeFunction<Void Function()>'.
  //                          ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
}

void testNativeCallableListenerAbstract() {
  final f = NativeCallable<Function>.listener(
      //    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
      // [cfe] Expected type 'NativeFunction<Function>' to be a valid and instantiated subtype of 'NativeType'.
      testNativeCallableListenerAbstract);
}

void testNativeCallableListenerMustReturnVoid() {
  final f = NativeCallable<NativeDoubleUnOp>.listener(myTimesThree);
  //                                                  ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_RETURN_VOID
  // [cfe] The return type of the function passed to NativeCallable.listener must be void rather than 'double'.
}

void testNativeCallableIsolateLocalGeneric() {
  NativeCallable<Function> generic<T extends Function>(T f) {
    late NativeCallable<NativeDoubleUnOp> result;
    result = NativeCallable.isolateLocal(f);
    //                      ^
    // [cfe] Expected type 'T' to be 'double Function(double)', which is the Dart type corresponding to 'NativeFunction<Double Function(Double)>'.
    //                                   ^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
    return result;
  }

  generic(myTimesThree);
}

void testNativeCallableIsolateLocalGeneric2() {
  NativeCallable<T> generic<T extends Function>() {
    late NativeCallable<T> result;
    result = NativeCallable.isolateLocal(myTimesThree);
    //       ^^^^^^^^^^^^^^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
    //                      ^
    // [cfe] Expected type 'NativeFunction<T>' to be a valid and instantiated subtype of 'NativeType'.
    return result;
  }

  generic<NativeDoubleUnOp>();
}

void testNativeCallableIsolateLocalWrongNativeFunctionSignature() {
  /**/ NativeCallable<IntUnOp>.isolateLocal(myTimesFour);
  //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
  // [cfe] Expected type 'NativeFunction<int Function(int)>' to be a valid and instantiated subtype of 'NativeType'.
}

void testNativeCallableIsolateLocalTypeMismatch() {
  NativeCallable<NativeDoubleUnOp> p;
  p = NativeCallable.isolateLocal(myTimesFour);
  //                 ^
  // [cfe] Expected type 'int Function(int)' to be 'double Function(double)', which is the Dart type corresponding to 'NativeFunction<Double Function(Double)>'.
  //                              ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
}

void testNativeCallableIsolateLocalTearOff() {
  DoubleUnOp fld = X().tearoff;
  NativeCallable<NativeDoubleUnOp> p;
  p = NativeCallable.isolateLocal(fld);
  //  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_EXCEPTION_VALUE
  //                 ^
  // [cfe] Expected an exceptional return value for a native callback returning 'double'.
}

void testNativeCallableIsolateLocalAbstract() {
  NativeCallable<Function>.isolateLocal(testNativeCallableIsolateLocalAbstract);
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
// [cfe] Expected type 'NativeFunction<Function>' to be a valid and instantiated subtype of 'NativeType'.
}

void testNativeCallableIsolateLocalFunctionExceptionValueMustBeConst() {
  final notAConst = 1.1;
  NativeCallable<NativeDoubleUnOp> p;
  p = NativeCallable.isolateLocal(myTimesThree, exceptionalReturn: notAConst);
  //                 ^
  // [cfe] Exceptional return value must be a constant.
  //                                                               ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_MUST_BE_A_CONSTANT
}

void testLookupFunctionGeneric() {
  Function generic<T extends Function>() {
    DynamicLibrary l = DynamicLibrary.process();
    Function result = () => "dummy";
    result = l.lookupFunction<T, DoubleUnOp>("cos");
    //         ^
    // [cfe] Expected type 'NativeFunction<T>' to be a valid and instantiated subtype of 'NativeType'.
    //                        ^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
    return result;
  }

  generic<NativeDoubleUnOp>();
}

void testLookupFunctionGeneric2() {
  Function generic<T extends Function>() {
    DynamicLibrary l = DynamicLibrary.process();
    Function result = () => "dummy";
    result = l.lookupFunction<NativeDoubleUnOp, T>("cos");
    //         ^
    // [cfe] Expected type 'T' to be 'double Function(double)', which is the Dart type corresponding to 'NativeFunction<Double Function(Double)>'.
    //                                          ^
    // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
    return result;
  }

  generic<DoubleUnOp>();
}

void testLookupFunctionWrongNativeFunctionSignature() {
  DynamicLibrary l = DynamicLibrary.process();
  l.lookupFunction<IntUnOp, IntUnOp>("cos");
  //^
  // [cfe] Expected type 'NativeFunction<int Function(int)>' to be a valid and instantiated subtype of 'NativeType'.
  //               ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
}

void testLookupFunctionTypeMismatch() {
  DynamicLibrary l = DynamicLibrary.process();
  l.lookupFunction<NativeDoubleUnOp, IntUnOp>("cos");
  //^
  // [cfe] Expected type 'int Function(int)' to be 'double Function(double)', which is the Dart type corresponding to 'NativeFunction<Double Function(Double)>'.
  //                                 ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
}

typedef PointervoidN = Void Function(Pointer<void>);
typedef PointervoidD = void Function(Pointer<void>);

void testLookupFunctionPointervoid() {
  DynamicLibrary l = DynamicLibrary.process();
  // TODO(https://dartbug.com/44593): This should be a compile-time error in CFE.
  // l.lookupFunction<PointervoidN, PointervoidD>("cos");
}

typedef PointerNFdynN = Void Function(Pointer<NativeFunction>);
typedef PointerNFdynD = void Function(Pointer<NativeFunction>);

void testLookupFunctionPointerNFdyn() {
  DynamicLibrary l = DynamicLibrary.process();
  // TODO(https://dartbug.com/44594): Should this be an error or not?
  // l.lookupFunction<PointerNFdynN, PointerNFdynD>("cos");
}

// error on missing field annotation
final class TestStruct extends Struct {
  @Double()
  external double x;

  external double y;
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_ANNOTATION_ON_STRUCT_FIELD
  //              ^
  // [cfe] Field 'y' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.
}

// Cannot extend structs.
class TestStruct3 extends TestStruct {}
//    ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] Class 'TestStruct' cannot be extended or implemented.
// [cfe] TestStruct 'TestStruct3' is empty. Empty structs and unions are undefined behavior.
// [cfe] The type 'TestStruct3' must be 'base', 'final' or 'sealed' because the supertype 'TestStruct' is 'final'.
//                        ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_STRUCT_CLASS

// error on double annotation
final class TestStruct4 extends Struct {
  @Double()
  /**/ @Double()
  //   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.EXTRA_ANNOTATION_ON_STRUCT_FIELD
  external double z;
  //              ^
  // [cfe] Field 'z' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.
}

// error on annotation not matching up
final class TestStruct5 extends Struct {
  /**/ @Int64()
  //   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISMATCHED_ANNOTATION_ON_STRUCT_FIELD
  external double z;
  //              ^
  // [cfe] Expected type 'double' to be 'int', which is the Dart type corresponding to 'Int64'.

  external Pointer notEmpty;
}

// error on annotation not matching up
final class TestStruct6 extends Struct {
  /**/ @Void()
  //   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISMATCHED_ANNOTATION_ON_STRUCT_FIELD
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_ANNOTATION_CONSTRUCTOR
  //    ^
  // [cfe] The class 'Void' is abstract and can't be instantiated.
  external double z;
  //              ^
  // [cfe] Field 'z' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.

  external Pointer notEmpty;
}

// error on annotation not matching up
final class TestStruct7 extends Struct {
  /**/ @Int8()
  //   ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISMATCHED_ANNOTATION_ON_STRUCT_FIELD
  external double y;
  //              ^
  // [cfe] Expected type 'double' to be 'int', which is the Dart type corresponding to 'Int8'.

  external double z;
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_ANNOTATION_ON_STRUCT_FIELD
  //              ^
  // [cfe] Field 'z' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.

  external Pointer notEmpty;
}

// error on field initializer on field
final class TestStruct8 extends Struct {
  @Double()
  double z = 10.0;
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_MUST_BE_EXTERNAL_IN_STRUCT
  // [cfe] Field 'z' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.

  external Pointer notEmpty;
}

// error on field initializer in constructor
final class TestStruct9 extends Struct {
  @Double()
  double z;
  //     ^
  // [analyzer] COMPILE_TIME_ERROR.FIELD_MUST_BE_EXTERNAL_IN_STRUCT
  // [cfe] Field 'z' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.

  external Pointer notEmpty;

  TestStruct9() : z = 0.0 {}
  //                ^
  // [cfe] Field 'z' is a dart:ffi Pointer to a struct field and therefore cannot be initialized before constructor execution.
}

// Struct classes may not be generic.
class TestStruct11<T> extends Struct<TestStruct11<dynamic>> {}
//    ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EMPTY_STRUCT
// [analyzer] COMPILE_TIME_ERROR.GENERIC_STRUCT_SUBCLASS
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
//                            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_TYPE_ARGUMENTS
// [cfe] Expected 0 type arguments.

// Structs may not appear inside structs (currently, there is no suitable
// annotation).
final class TestStruct12 extends Struct {
  /**/ @Pointer
  //   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ANNOTATION
  //    ^
  // [cfe] This can't be used as an annotation; an annotation should be a reference to a compile-time constant variable, or a call to a constant constructor.
  external TestStruct9 struct;

  external Pointer notEmpty;
}

class DummyAnnotation {
  const DummyAnnotation();
}

// Structs fields may have other annotations.
final class TestStruct13 extends Struct {
  @DummyAnnotation()
  @Double()
  external double z;
}

// Cannot extend native types.

class ENativeType extends NativeType {}
//                        ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'NativeType' can't be extended outside of its library because it's a final class.

class EInt8 extends Int8 {}
//                  ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Int8' can't be extended outside of its library because it's a final class.

class EInt16 extends Int16 {}
//                   ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Int16' can't be extended outside of its library because it's a final class.

class EInt32 extends Int32 {}
//                   ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Int32' can't be extended outside of its library because it's a final class.

class EInt64 extends Int64 {}
//                   ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Int64' can't be extended outside of its library because it's a final class.

class EUint8 extends Uint8 {}
//                   ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Uint8' can't be extended outside of its library because it's a final class.

class EUint16 extends Uint16 {}
//                    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Uint16' can't be extended outside of its library because it's a final class.

class EUint32 extends Uint32 {}
//                    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Uint32' can't be extended outside of its library because it's a final class.

class EUint64 extends Uint64 {}
//                    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Uint64' can't be extended outside of its library because it's a final class.

class EIntPtr extends IntPtr {}
//    ^
// [cfe] Class 'IntPtr' cannot be extended or implemented.
// [cfe] Classes extending 'AbiSpecificInteger' must have exactly one 'AbiSpecificIntegerMapping' annotation specifying the mapping from ABI to a NativeType integer with a fixed size.
// [cfe] Classes extending 'AbiSpecificInteger' must have exactly one const constructor, no other members, and no type arguments.
//                    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'IntPtr' can't be extended outside of its library because it's a final class.

class EFloat extends Float {}
//                   ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Float' can't be extended outside of its library because it's a final class.

class EDouble extends Double {}
//                    ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Double' can't be extended outside of its library because it's a final class.

class EVoid extends Void {}
//                  ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Void' can't be extended outside of its library because it's a final class.

class ENativeFunction extends NativeFunction {}
//                            ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'NativeFunction' can't be extended outside of its library because it's a final class.

class EPointer extends Pointer {}
//    ^
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
// [cfe] The superclass, 'Pointer', has no unnamed constructor that takes no arguments.
//                     ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS
// [cfe] The class 'Pointer' can't be extended outside of its library because it's a final class.

// Cannot implement native natives or Struct.

// Cannot extend native types.

class INativeType implements NativeType {}
//                           ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'NativeType' can't be implemented outside of its library because it's a final class.

class IInt8 implements Int8 {}
//                     ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Int8' can't be implemented outside of its library because it's a final class.

class IInt16 implements Int16 {}
//                      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Int16' can't be implemented outside of its library because it's a final class.

class IInt32 implements Int32 {}
//                      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Int32' can't be implemented outside of its library because it's a final class.

class IInt64 implements Int64 {}
//                      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Int64' can't be implemented outside of its library because it's a final class.

class IUint8 implements Uint8 {}
//                      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Uint8' can't be implemented outside of its library because it's a final class.

class IUint16 implements Uint16 {}
//                       ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Uint16' can't be implemented outside of its library because it's a final class.

class IUint32 implements Uint32 {}
//                       ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Uint32' can't be implemented outside of its library because it's a final class.

class IUint64 implements Uint64 {}
//                       ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Uint64' can't be implemented outside of its library because it's a final class.

class IIntPtr implements IntPtr {}
//    ^
// [cfe] Class 'Object' cannot be extended or implemented.
//                       ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_STRUCT_CLASS
// [cfe] The class 'IntPtr' can't be implemented outside of its library because it's a final class.

class IFloat implements Float {}
//                      ^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Float' can't be implemented outside of its library because it's a final class.

class IDouble implements Double {}
//                       ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Double' can't be implemented outside of its library because it's a final class.

class IVoid implements Void {}
//                     ^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Void' can't be implemented outside of its library because it's a final class.

class INativeFunction implements NativeFunction {}
//                               ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'NativeFunction' can't be implemented outside of its library because it's a final class.

class IPointer implements Pointer {}
//    ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
// [cfe] Subtypes of deeply immutable classes must be deeply immutable.
// [cfe] The non-abstract class 'IPointer' is missing implementations for these members:
//                        ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Pointer' can't be implemented outside of its library because it's a final class.

class IStruct implements Struct {}
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] Class 'Object' cannot be extended or implemented.
// [cfe] The type 'IStruct' must be 'base', 'final' or 'sealed' because the supertype 'Struct' is 'base'.
//                       ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Struct' can't be implemented outside of its library because it's a base class.

class IOpaque implements Opaque {}
//    ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
// [cfe] Class 'Object' cannot be extended or implemented.
// [cfe] The type 'IOpaque' must be 'base', 'final' or 'sealed' because the supertype 'Opaque' is 'base'.
//                       ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
// [cfe] The class 'Opaque' can't be implemented outside of its library because it's a base class.

class MyClass {
  int x;
  MyClass(this.x);
}

final testLibrary = DynamicLibrary.process();

void testHandleVariance() {
  // Taking a more specific argument is okay.
  testLibrary.lookupFunction<Handle Function(Handle), Object Function(MyClass)>(
      "PassObjectToC");

  // Returning a more specific type than Handle is okay too: it will be checked at runtime.
  testLibrary.lookupFunction<Handle Function(Handle), MyClass Function(Object)>(
      "PassObjectToC");
}

final class TestStruct1001 extends Struct {
  external Handle handle;
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_FIELD_TYPE_IN_STRUCT
  //              ^
  // [cfe] Field 'handle' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.

  external Pointer notEmpty;
}

final class TestStruct1002 extends Struct {
  /**/ @Handle()
  //   ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_ANNOTATION_CONSTRUCTOR
  //    ^
  // [cfe] The class 'Handle' is abstract and can't be instantiated.
  external Object handle;
  //       ^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_FIELD_TYPE_IN_STRUCT
  //              ^
  // [cfe] Field 'handle' requires exactly one annotation to declare its native type, which cannot be Void. dart:ffi Structs and Unions cannot have regular Dart fields.

  external Pointer notEmpty;
}

final class EmptyStruct extends Struct {}
//          ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EMPTY_STRUCT
// [cfe] Struct 'EmptyStruct' is empty. Empty structs and unions are undefined behavior.

void testEmptyStructLookupFunctionArgument() {
  testLibrary.lookupFunction<
      /**/ Void Function(EmptyStruct),
      //   ^^^^^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
      void Function(EmptyStruct)>("DoesNotExist");
}

void testEmptyStructLookupFunctionReturn() {
  testLibrary.lookupFunction<EmptyStruct Function(), EmptyStruct Function()>(
      //                     ^^^^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
      "DoesNotExist");
}

void testEmptyStructAsFunctionArgument() {
  final Pointer<NativeFunction<Void Function(EmptyStruct)>> pointer =
      Pointer.fromAddress(1234);
  pointer.asFunction<void Function(EmptyStruct)>();
  //                 ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER
}

void testEmptyStructAsFunctionReturn() {
  final Pointer<NativeFunction<EmptyStruct Function()>> pointer =
      Pointer.fromAddress(1234);
  pointer.asFunction<EmptyStruct Function()>();
  //                 ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_NATIVE_FUNCTION_TYPE_ARGUMENT_TO_POINTER
}

void _consumeEmptyStruct(EmptyStruct e) => print(e);

void testEmptyStructFromFunctionArgument() {
  Pointer.fromFunction<Void Function(EmptyStruct)>(_consumeEmptyStruct);
  //                   ^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
}

/**/ EmptyStruct _returnEmptyStruct() => EmptyStruct();
//                                       ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CREATION_OF_STRUCT_OR_UNION
// [cfe] Subclasses of 'Struct' and 'Union' are backed by native memory, and can't be instantiated by a generative constructor. Try allocating it via allocation, or load from a 'Pointer'.

void testEmptyStructFromFunctionReturn() {
  Pointer.fromFunction<EmptyStruct Function()>(_returnEmptyStruct);
  //                   ^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_NATIVE_FUNCTION_TYPE
}

final class HasNestedEmptyStruct extends Struct {
  external EmptyStruct nestedEmptyStruct;
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EMPTY_STRUCT

  external Pointer notEmpty;
}

void testAllocateGeneric() {
  Pointer<T> generic<T extends SizedNativeType>() {
    Pointer<T> pointer = nullptr;
    pointer = calloc();
    //        ^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
    //              ^
    // [cfe] Expected type 'T' to be a valid and instantiated subtype of 'NativeType'.
    return pointer;
  }

  Pointer p = generic<Int64>();
}

void testAllocateInvalidType() {
  /**/ calloc();
  //   ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
  //         ^
  // [cfe] Expected type 'SizedNativeType' to be a valid and instantiated subtype of 'NativeType'.

  /**/ calloc<Struct>();
  //   ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
  //         ^
  // [cfe] Expected type 'Struct' to be a valid and instantiated subtype of 'NativeType'.

  /**/ calloc<Union>();
  //   ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
  //         ^
  // [cfe] Expected type 'Union' to be a valid and instantiated subtype of 'NativeType'.

  /**/ calloc<AbiSpecificInteger>();
  //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
  //         ^
  // [cfe] Expected type 'AbiSpecificInteger' to be a valid and instantiated subtype of 'NativeType'.
}

// TODO(https://dartbug.com/36780): Improve error messages.
void testCreateInvalidType() {
  /**/ Struct.create<Struct>();
  //   ^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
  //          ^
  // [cfe] Expected type 'Struct' to be a valid and instantiated subtype of 'NativeType'.
  /**/ Union.create<Union>();
  //   ^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
  //         ^
  // [cfe] Expected type 'Union' to be a valid and instantiated subtype of 'NativeType'.
}

void testRefStruct() {
  final myStructPointer = calloc<TestStruct13>();
  Pointer<Struct> structPointer = myStructPointer;
  /**/ structPointer.ref;
  //   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
  //                 ^
  // [cfe] Expected type 'Struct' to be a valid and instantiated subtype of 'NativeType'.
  calloc.free(myStructPointer);
}

void testRefWithFinalizerStruct() {
  final myStructPointer = calloc<TestStruct13>();
  Pointer<Struct> structPointer = myStructPointer;
  /**/ structPointer.refWithFinalizer(calloc.nativeFree);
  //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
  //                 ^
  // [cfe] Expected type 'Struct' to be a valid and instantiated subtype of 'NativeType'.
  calloc.free(myStructPointer);
}

T genericRef<T extends Struct>(Pointer<T> p) => p.ref;
//                                              ^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
//                                                ^
// [cfe] Expected type 'T' to be a valid and instantiated subtype of 'NativeType'.

T genericRef2<T extends Struct>(Pointer<T> p) => p.cast<T>().ref;
//                                               ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
//                                                           ^
// [cfe] Expected type 'T' to be a valid and instantiated subtype of 'NativeType'.

T genericRef3<T extends Struct>(Pointer<T> p) => p[0];
//                                               ^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
//                                                ^
// [cfe] Expected type 'T' to be a valid and instantiated subtype of 'NativeType'.

T genericRef4<T extends Struct>(Array<T> p) => p[0];
//                                             ^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
//                                              ^
// [cfe] Expected type 'T' to be a valid and instantiated subtype of 'NativeType'.

T genericRefWithFinalizer<T extends Struct>(Pointer<T> p) =>
    p.refWithFinalizer(calloc.nativeFree);
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
//    ^
// [cfe] Expected type 'T' to be a valid and instantiated subtype of 'NativeType'.

T genericRefWithFinalizer2<T extends Struct>(Pointer<T> p) =>
    p.cast<T>().refWithFinalizer(calloc.nativeFree);
//  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
//              ^
// [cfe] Expected type 'T' to be a valid and instantiated subtype of 'NativeType'.

void testSizeOfGeneric() {
  int generic<T extends Pointer>() {
    int size = sizeOf<IntPtr>();
    size = sizeOf<T>();
    //     ^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
    // [cfe] Expected type 'T' to be a valid and instantiated subtype of 'NativeType'.
    return size;
  }

  int size = generic<Pointer<Int64>>();
}

void testSizeOfInvalidType() {
  sizeOf();
//^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
// [cfe] Expected type 'SizedNativeType' to be a valid and instantiated subtype of 'NativeType'.

  sizeOf<Struct>();
//^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
// [cfe] Expected type 'Struct' to be a valid and instantiated subtype of 'NativeType'.

  sizeOf<Union>();
//^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
// [cfe] Expected type 'Union' to be a valid and instantiated subtype of 'NativeType'.

  sizeOf<AbiSpecificInteger>();
//^^^^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_CONSTANT_TYPE_ARGUMENT
// [cfe] Expected type 'AbiSpecificInteger' to be a valid and instantiated subtype of 'NativeType'.
}


final class TestStruct1400 extends Struct {
  @Array(8)
  @Array(8)
//^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.EXTRA_SIZE_ANNOTATION_CARRAY
  external Array<Uint8> a0;
  //                    ^
  // [cfe] Field 'a0' must have exactly one 'Array' annotation.
}

final class TestStruct1401 extends Struct {
  external Array<Uint8> a0;
  //       ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MISSING_SIZE_ANNOTATION_CARRAY
  //                    ^
  // [cfe] Field 'a0' must have exactly one 'Array' annotation.

  external Pointer<Uint8> notEmpty;
}

final class TestStruct1402 extends Struct {
  /**/ @Array(8, 8, 8)
  //   ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Array<Uint8>> a0;
  //                           ^
  // [cfe] Field 'a0' must have an 'Array' annotation that matches the dimensions.

  external Pointer<Uint8> notEmpty;
}

final class TestStruct1403 extends Struct {
  /**/ @Array(8, 8)
  //   ^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Array<Array<Uint8>>> a0;
  //                                  ^
  // [cfe] Field 'a0' must have an 'Array' annotation that matches the dimensions.

  external Pointer<Uint8> notEmpty;
}

final class TestStruct1404 extends Struct {
  /**/ @Array.multi([8, 8, 8])
  //   ^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Array<Uint8>> a0;
  //                           ^
  // [cfe] Field 'a0' must have an 'Array' annotation that matches the dimensions.

  external Pointer<Uint8> notEmpty;
}

final class TestStruct1405 extends Struct {
  /**/ @Array.multi([8, 8])
  //   ^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  external Array<Array<Array<Uint8>>> a0;
  //                                  ^
  // [cfe] Field 'a0' must have an 'Array' annotation that matches the dimensions.

  external Pointer<Uint8> notEmpty;
}

void testLookupFunctionIsLeafMustBeConst() {
  bool notAConst = false;
  DynamicLibrary l = DynamicLibrary.process();
  /**/ l.lookupFunction<NativeDoubleUnOp, DoubleUnOp>("timesFour",
      // ^
      // [cfe] Argument 'isLeaf' must be a constant.
      isLeaf: notAConst);
  //          ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_MUST_BE_A_CONSTANT
}

void testAsFunctionIsLeafMustBeConst() {
  bool notAConst = false;
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = p.asFunction(isLeaf: notAConst);
  //            ^
  // [cfe] Argument 'isLeaf' must be a constant.
  //                               ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_MUST_BE_A_CONSTANT
}

typedef NativeTakesHandle = Void Function(Handle);
typedef TakesHandle = void Function(Object);

void testLookupFunctionTakesHandle() {
  DynamicLibrary l = DynamicLibrary.process();
  l.lookupFunction<NativeTakesHandle, TakesHandle>("takesHandle", isLeaf: true);
  //^
  // [cfe] FFI leaf call must not have Handle argument types.
  //               ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LEAF_CALL_MUST_NOT_TAKE_HANDLE
}

void testAsFunctionTakesHandle() {
  Pointer<NativeFunction<NativeTakesHandle>> p = Pointer.fromAddress(1337);
  TakesHandle f = p.asFunction(isLeaf: true);
  //                ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LEAF_CALL_MUST_NOT_TAKE_HANDLE
  // [cfe] FFI leaf call must not have Handle argument types.
}

typedef NativeReturnsHandle = Handle Function();
typedef ReturnsHandle = Object Function();

void testLookupFunctionReturnsHandle() {
  DynamicLibrary l = DynamicLibrary.process();
  /**/ l.lookupFunction<NativeReturnsHandle, ReturnsHandle>("returnsHandle",
      // ^
      // [cfe] FFI leaf call must not have Handle return type.
      //                ^^^^^^^^^^^^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.LEAF_CALL_MUST_NOT_RETURN_HANDLE
      isLeaf: true);
}

void testAsFunctionReturnsHandle() {
  Pointer<NativeFunction<NativeReturnsHandle>> p = Pointer.fromAddress(1337);
  ReturnsHandle f = p.asFunction(isLeaf: true);
  //                  ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.LEAF_CALL_MUST_NOT_RETURN_HANDLE
  // [cfe] FFI leaf call must not have Handle return type.
}

@Packed(1)
final class TestStruct1600 extends Struct {
  external Pointer<Uint8> notEmpty;
}

@Packed(1)
/**/ @Packed(1)
//   ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.PACKED_ANNOTATION
final class TestStruct1601 extends Struct {
  //        ^
  // [cfe] Struct 'TestStruct1601' must have at most one 'Packed' annotation.
  external Pointer<Uint8> notEmpty;
}

@Packed(3)
//      ^
// [analyzer] COMPILE_TIME_ERROR.PACKED_ANNOTATION_ALIGNMENT
final class TestStruct1602 extends Struct {
  //        ^
  // [cfe] Only packing to 1, 2, 4, 8, and 16 bytes is supported.
  external Pointer<Uint8> notEmpty;
}

@Packed(0)
//      ^
// [analyzer] COMPILE_TIME_ERROR.PACKED_ANNOTATION_ALIGNMENT
final class TestStruct1607 extends Struct {
  //        ^
  // [cfe] Only packing to 1, 2, 4, 8, and 16 bytes is supported.
  external Pointer<Uint8> notEmpty;
}

final class TestStruct1800 extends Struct {
  external Pointer<Uint8> notEmpty;

  @Array(-1)
  //     ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_POSITIVE_ARRAY_DIMENSION
  external Array<Uint8> inlineArray;
  //                    ^
  // [cfe] Array dimensions must be positive numbers.
}

final class TestStruct1801 extends Struct {
  external Pointer<Uint8> notEmpty;

  /**/ @Array(1, -1)
  //   ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  //             ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_POSITIVE_ARRAY_DIMENSION
  external Array<Uint8> inlineArray;
  //                    ^
  // [cfe] Array dimensions must be positive numbers.
  // [cfe] Field 'inlineArray' must have an 'Array' annotation that matches the dimensions.
}

final class TestStruct1802 extends Struct {
  external Pointer<Uint8> notEmpty;

  /**/ @Array.multi([2, 2, 2, 2, 2, 2, -1])
  //   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SIZE_ANNOTATION_DIMENSIONS
  //                                   ^^
  // [analyzer] COMPILE_TIME_ERROR.NON_POSITIVE_ARRAY_DIMENSION
  external Array<Uint8> inlineArray;
  //                    ^
  // [cfe] Array dimensions must be positive numbers.
  // [cfe] Field 'inlineArray' must have an 'Array' annotation that matches the dimensions.
}

@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: IntPtr(),
  //                ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED
  Abi.androidIA32: AbiSpecificInteger1(),
  //               ^^^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ABI_SPECIFIC_INTEGER_MAPPING_UNSUPPORTED
})
/**/ @AbiSpecificIntegerMapping({})
//    ^^^^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.ABI_SPECIFIC_INTEGER_MAPPING_EXTRA
final class AbiSpecificInteger1 extends AbiSpecificInteger {
  //        ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ABI_SPECIFIC_INTEGER_INVALID
  // [cfe] Classes extending 'AbiSpecificInteger' must have exactly one 'AbiSpecificIntegerMapping' annotation specifying the mapping from ABI to a NativeType integer with a fixed size.
  // [cfe] Classes extending 'AbiSpecificInteger' must have exactly one const constructor, no other members, and no type arguments.
  const AbiSpecificInteger1();
  //    ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD

  int get a => 4;

  external int b;
}

// dart format on

class AbiSpecificInteger2 implements AbiSpecificInteger {
  //  ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
  // [cfe] Class 'Object' cannot be extended or implemented.
  // [cfe] The type 'AbiSpecificInteger2' must be 'base', 'final' or 'sealed' because the supertype 'AbiSpecificInteger' is 'base'.
  //                                 ^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
  // [cfe] The class 'AbiSpecificInteger' can't be implemented outside of its library because it's a base class.
  const AbiSpecificInteger2();
}

class AbiSpecificInteger3 extends AbiSpecificInteger1 {
  //  ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
  // [cfe] Class 'AbiSpecificInteger1' cannot be extended or implemented.
  // [cfe] Classes extending 'AbiSpecificInteger' must have exactly one 'AbiSpecificIntegerMapping' annotation specifying the mapping from ABI to a NativeType integer with a fixed size.
  // [cfe] The type 'AbiSpecificInteger3' must be 'base', 'final' or 'sealed' because the supertype 'AbiSpecificInteger1' is 'final'.
  //                              ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_STRUCT_CLASS
  const AbiSpecificInteger3();
  //    ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD
}

class AbiSpecificInteger4 implements AbiSpecificInteger1 {
  //  ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NON_ABSTRACT_CLASS_INHERITS_ABSTRACT_MEMBER
  // [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_BASE_OR_FINAL_IS_NOT_BASE_FINAL_OR_SEALED
  // [cfe] Class 'Object' cannot be extended or implemented.
  // [cfe] The non-abstract class 'AbiSpecificInteger4' is missing implementations for these members:
  // [cfe] The type 'AbiSpecificInteger4' must be 'base', 'final' or 'sealed' because the supertype 'AbiSpecificInteger1' is 'final'.
  //                                 ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_USE_OF_TYPE_OUTSIDE_LIBRARY
  // [analyzer] COMPILE_TIME_ERROR.SUBTYPE_OF_STRUCT_CLASS
  // [cfe] The class 'AbiSpecificInteger' can't be implemented outside of its library because it's a base class.
  const AbiSpecificInteger4();
}

final class MyFinalizableStruct extends Struct implements Finalizable {
  //        ^^^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.COMPOUND_IMPLEMENTS_FINALIZABLE
  // [cfe] Struct 'MyFinalizableStruct' can't implement Finalizable.
  external Pointer<Void> field;
}

void testReturnVoidNotVoid() {
  // Taking a more specific argument is okay.
  testLibrary.lookupFunction<Handle Function(), void Function()>("unused");
  //          ^
  // [cfe] Expected type 'void Function()' to be 'Never Function()', which is the Dart type corresponding to 'NativeFunction<Handle Function()>'.
  //                                            ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.MUST_BE_A_SUBTYPE
}
