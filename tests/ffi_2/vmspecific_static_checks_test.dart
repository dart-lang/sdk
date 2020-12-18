// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi extra checks
//
// SharedObjects=ffi_test_dynamic_library ffi_test_functions

import 'dart:ffi';

import "package:ffi/ffi.dart";

import 'dylib_utils.dart';

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
  testLookupFunctionGeneric();
  testLookupFunctionGeneric2();
  testLookupFunctionWrongNativeFunctionSignature();
  testLookupFunctionTypeMismatch();
  testNativeFunctionSignatureInvalidReturn();
  testNativeFunctionSignatureInvalidParam();
  testNativeFunctionSignatureInvalidOptionalNamed();
  testNativeFunctionSignatureInvalidOptionalPositional();
  testHandleVariance();
  testEmptyStructLookupFunctionArgument();
  testEmptyStructLookupFunctionReturn();
  testEmptyStructAsFunctionArgument();
  testEmptyStructAsFunctionReturn();
  testEmptyStructFromFunctionArgument();
  testEmptyStructFromFunctionReturn();
}

typedef Int8UnOp = Int8 Function(Int8);
typedef IntUnOp = int Function(int);

void testGetGeneric() {
  int generic(Pointer p) {
    int result;
    result = p.value; //# 20: compile-time error
    return result;
  }

  Pointer<Int8> p = allocate();
  p.value = 123;
  Pointer loseType = p;
  generic(loseType);
  free(p);
}

void testGetGeneric2() {
  T generic<T extends Object>() {
    Pointer<Int8> p = allocate();
    p.value = 123;
    T result;
    result = p.value; //# 21: compile-time error
    free(p);
    return result;
  }

  generic<int>();
}

void testGetVoid() {
  Pointer<IntPtr> p1 = allocate();
  Pointer<Void> p2 = p1.cast();

  p2.value; //# 22: compile-time error

  free(p1);
}

void testGetNativeFunction() {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = p.value; //# 23: compile-time error
}

void testGetNativeType() {
  // Is it possible to obtain a Pointer<NativeType> at all?
}

void testGetTypeMismatch() {
  Pointer<Pointer<Int16>> p = allocate();
  Pointer<Int16> typedNull = nullptr;
  p.value = typedNull;

  // this fails to compile due to type mismatch
  Pointer<Int8> p2 = p.value; //# 25: compile-time error

  free(p);
}

void testSetGeneric() {
  void generic(Pointer p) {
    p.value = 123; //# 26: compile-time error
  }

  Pointer<Int8> p = allocate();
  p.value = 123;
  Pointer loseType = p;
  generic(loseType);
  free(p);
}

void testSetGeneric2() {
  void generic<T extends Object>(T arg) {
    Pointer<Int8> p = allocate();
    p.value = arg; //# 27: compile-time error
    free(p);
  }

  generic<int>(123);
}

void testSetVoid() {
  Pointer<IntPtr> p1 = allocate();
  Pointer<Void> p2 = p1.cast();

  p2.value = 1234; //# 28: compile-time error

  free(p1);
}

void testSetNativeFunction() {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = (a) => a + 1;
  p.value = f; //# 29: compile-time error
}

void testSetNativeType() {
  // Is it possible to obtain a Pointer<NativeType> at all?
}

void testSetTypeMismatch() {
  // the pointer to pointer types must match up
  Pointer<Int8> pHelper = allocate();
  pHelper.value = 123;

  Pointer<Pointer<Int16>> p = allocate();

  // this fails to compile due to type mismatch
  p.value = pHelper; //# 40: compile-time error

  free(pHelper);
  free(p);
}

void testAsFunctionGeneric() {
  T generic<T extends Function>() {
    Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
    Function f;
    f = p.asFunction<T>(); //# 11: compile-time error
    return f;
  }

  generic<IntUnOp>();
}

void testAsFunctionGeneric2() {
  generic(Pointer<NativeFunction> p) {
    Function f;
    f = p.asFunction<IntUnOp>(); //# 12: compile-time error
    return f;
  }

  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  generic(p);
}

void testAsFunctionWrongNativeFunctionSignature() {
  Pointer<NativeFunction<IntUnOp>> p;
  Function f = p.asFunction<IntUnOp>(); //# 13: compile-time error
}

typedef IntBinOp = int Function(int, int);

void testAsFunctionTypeMismatch() {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntBinOp f = p.asFunction(); //# 14: compile-time error
}

typedef NativeDoubleUnOp = Double Function(Double);
typedef DoubleUnOp = double Function(double);

double myTimesThree(double d) => d * 3;

int myTimesFour(int i) => i * 4;

void testFromFunctionGeneric() {
  Pointer<NativeFunction> generic<T extends Function>(T f) {
    Pointer<NativeFunction<NativeDoubleUnOp>> result;
    result = Pointer.fromFunction(f); //# 70: compile-time error
    return result;
  }

  generic(myTimesThree);
}

void testFromFunctionGeneric2() {
  Pointer<NativeFunction<T>> generic<T extends Function>() {
    Pointer<NativeFunction<T>> result;
    result = Pointer.fromFunction(myTimesThree); //# 71: compile-time error
    return result;
  }

  generic<NativeDoubleUnOp>();
}

void testFromFunctionWrongNativeFunctionSignature() {
  Pointer.fromFunction<IntUnOp>(myTimesFour); //# 72: compile-time error
}

void testFromFunctionTypeMismatch() {
  Pointer<NativeFunction<NativeDoubleUnOp>> p;
  p = Pointer.fromFunction(myTimesFour); //# 73: compile-time error
}

void testFromFunctionClosure() {
  DoubleUnOp someClosure = (double z) => z / 27.0;
  Pointer<NativeFunction<NativeDoubleUnOp>> p;
  p = Pointer.fromFunction(someClosure); //# 74: compile-time error
}

class X {
  double tearoff(double d) => d / 27.0;
}

void testFromFunctionTearOff() {
  DoubleUnOp fld = X().tearoff;
  Pointer<NativeFunction<NativeDoubleUnOp>> p;
  p = Pointer.fromFunction(fld); //# 75: compile-time error
}

void testFromFunctionAbstract() {
  Pointer.fromFunction<Function>(//# 76: compile-time error
      testFromFunctionAbstract); //# 76: compile-time error
}

void testLookupFunctionGeneric() {
  Function generic<T extends Function>() {
    DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
    Function result;
    result = l.lookupFunction<T, DoubleUnOp>("cos"); //# 15: compile-time error
    return result;
  }

  generic<NativeDoubleUnOp>();
}

void testLookupFunctionGeneric2() {
  Function generic<T extends Function>() {
    DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
    Function result;
    result = //# 16: compile-time error
        l.lookupFunction<NativeDoubleUnOp, T>("cos"); //# 16: compile-time error
    return result;
  }

  generic<DoubleUnOp>();
}

void testLookupFunctionWrongNativeFunctionSignature() {
  DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  l.lookupFunction<IntUnOp, IntUnOp>("cos"); //# 17: compile-time error
}

void testLookupFunctionTypeMismatch() {
  DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  l.lookupFunction<NativeDoubleUnOp, IntUnOp>("cos"); //# 18: compile-time error
}

// TODO(dacoharkes): make the next 4 test compile errors
typedef Invalid1 = int Function(Int8);
typedef Invalid2 = Int8 Function(int);
typedef Invalid3 = Int8 Function({Int8 named});
typedef Invalid4 = Int8 Function([Int8 positional]);

void testNativeFunctionSignatureInvalidReturn() {
  // Pointer<NativeFunction<Invalid1>> p = fromAddress(999);
}

void testNativeFunctionSignatureInvalidParam() {
  // Pointer<NativeFunction<Invalid2>> p = fromAddress(999);
}

void testNativeFunctionSignatureInvalidOptionalNamed() {
  // Pointer<NativeFunction<Invalid3>> p = fromAddress(999);
}

void testNativeFunctionSignatureInvalidOptionalPositional() {
  // Pointer<NativeFunction<Invalid4>> p = fromAddress(999);
}

// error on missing field annotation
class TestStruct extends Struct {
  @Double()
  double x;

  double y; //# 50: compile-time error
}

// Cannot extend structs.
class TestStruct3 extends TestStruct {} //# 52: compile-time error

// error on double annotation
class TestStruct4 extends Struct {
  @Double()
  @Double() //# 53: compile-time error
  double z;
}

// error on annotation not matching up
class TestStruct5 extends Struct {
  @Int64() //# 54: compile-time error
  double z; //# 54: compile-time error
}

// error on annotation not matching up
class TestStruct6 extends Struct {
  @Void() //# 55: compile-time error
  double z; //# 55: compile-time error
}

// error on annotation not matching up
class TestStruct7 extends Struct {
  @NativeType() //# 56: compile-time error
  double z; //# 56: compile-time error
}

// error on field initializer on field
class TestStruct8 extends Struct {
  @Double() //# 57: compile-time error
  double z = 10.0; //# 57: compile-time error
}

// error on field initializer in constructor
class TestStruct9 extends Struct {
  @Double()
  double z;

  TestStruct9() : z = 0.0 {} //# 58: compile-time error
}

// Struct classes may not be generic.
class TestStruct11<T> extends //# 60: compile-time error
    Struct<TestStruct11<dynamic>> {} //# 60: compile-time error

// Structs may not appear inside structs (currently, there is no suitable
// annotation).
class TestStruct12 extends Struct {
  @Pointer //# 61: compile-time error
  TestStruct9 struct; //# 61: compile-time error
}

class DummyAnnotation {
  const DummyAnnotation();
}

// Structs fields may have other annotations.
class TestStruct13 extends Struct {
  @DummyAnnotation()
  @Double()
  double z;
}

// Cannot extend native types.

class ENativeType extends NativeType {} //# 90: compile-time error

class EInt8 extends Int8 {} //# 91: compile-time error

class EInt16 extends Int16 {} //# 92: compile-time error

class EInt32 extends Int32 {} //# 93: compile-time error

class EInt64 extends Int64 {} //# 94: compile-time error

class EUint8 extends Uint8 {} //# 95: compile-time error

class EUint16 extends Uint16 {} //# 96: compile-time error

class EUint32 extends Uint32 {} //# 97: compile-time error

class EUint64 extends Uint64 {} //# 98: compile-time error

class EIntPtr extends IntPtr {} //# 99: compile-time error

class EFloat extends Float {} //# 910: compile-time error

class EDouble extends Double {} //# 911: compile-time error

class EVoid extends Void {} //# 912: compile-time error

class ENativeFunction extends NativeFunction {} //# 913: compile-time error

class EPointer extends Pointer {} //# 914: compile-time error

// Cannot implement native natives or Struct.

// Cannot extend native types.

class INativeType implements NativeType {} //# 80: compile-time error

class IInt8 implements Int8 {} //# 81: compile-time error

class IInt16 implements Int16 {} //# 82: compile-time error

class IInt32 implements Int32 {} //# 83: compile-time error

class IInt64 implements Int64 {} //# 84: compile-time error

class IUint8 implements Uint8 {} //# 85: compile-time error

class IUint16 implements Uint16 {} //# 86: compile-time error

class IUint32 implements Uint32 {} //# 87: compile-time error

class IUint64 implements Uint64 {} //# 88: compile-time error

class IIntPtr implements IntPtr {} //# 88: compile-time error

class IFloat implements Float {} //# 810: compile-time error

class IDouble implements Double {} //# 811: compile-time error

class IVoid implements Void {} //# 812: compile-time error

class INativeFunction //# 813: compile-time error
    implements //# 813: compile-time error
        NativeFunction {} //# 813: compile-time error

class IPointer implements Pointer {} //# 814: compile-time error

class IStruct implements Struct {} //# 815: compile-time error

class MyClass {
  int x;
  MyClass(this.x);
}

final testLibrary = dlopenPlatformSpecific("ffi_test_functions");

void testHandleVariance() {
  // Taking a more specific argument is okay.
  testLibrary.lookupFunction<Handle Function(Handle), Object Function(MyClass)>(
      "PassObjectToC");

  // Requiring a more specific return type is not, this requires a cast from
  // the user.
  testLibrary.lookupFunction< //# 1000: compile-time error
      Handle Function(Handle), //# 1000: compile-time error
      MyClass Function(Object)>("PassObjectToC"); //# 1000: compile-time error
}

class TestStruct1001 extends Struct {
  Handle handle; //# 1001: compile-time error
}

class TestStruct1002 extends Struct {
  @Handle() //# 1002: compile-time error
  Object handle; //# 1002: compile-time error
}

class EmptyStruct extends Struct {}

void testEmptyStructLookupFunctionArgument() {
  testLibrary.lookupFunction< //# 1100: compile-time error
      Void Function(EmptyStruct), //# 1100: compile-time error
      void Function(EmptyStruct)>("DoesNotExist"); //# 1100: compile-time error
}

void testEmptyStructLookupFunctionReturn() {
  testLibrary.lookupFunction< //# 1101: compile-time error
      EmptyStruct Function(), //# 1101: compile-time error
      EmptyStruct Function()>("DoesNotExist"); //# 1101: compile-time error
}

void testEmptyStructAsFunctionArgument() {
  final pointer =
      Pointer<NativeFunction<Void Function(EmptyStruct)>>.fromAddress(1234);
  pointer.asFunction<void Function(EmptyStruct)>(); //# 1102: compile-time error
}

void testEmptyStructAsFunctionReturn() {
  final pointer =
      Pointer<NativeFunction<EmptyStruct Function()>>.fromAddress(1234);
  pointer.asFunction<EmptyStruct Function()>(); //# 1103: compile-time error
}

void _consumeEmptyStruct(EmptyStruct e) {
  print(e);
}

void testEmptyStructFromFunctionArgument() {
  Pointer.fromFunction<Void Function(EmptyStruct)>(//# 1104: compile-time error
      _consumeEmptyStruct); //# 1104: compile-time error
}

EmptyStruct _returnEmptyStruct() {
  return EmptyStruct();
}

void testEmptyStructFromFunctionReturn() {
  Pointer.fromFunction<EmptyStruct Function()>(//# 1105: compile-time error
      _returnEmptyStruct); //# 1105: compile-time error
}

class HasNestedEmptyStruct extends Struct {
  EmptyStruct nestedEmptyStruct; //# 1106: compile-time error
}
