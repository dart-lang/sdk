// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi extra checks
//
// SharedObjects=ffi_test_dynamic_library

library FfiTest;

import 'dart:ffi' as ffi;
import 'dart:ffi' show Pointer;

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
  testLookupFunctionGeneric();
  testLookupFunctionGeneric2();
  testLookupFunctionWrongNativeFunctionSignature();
  testLookupFunctionTypeMismatch();
  testNativeFunctionSignatureInvalidReturn();
  testNativeFunctionSignatureInvalidParam();
  testNativeFunctionSignatureInvalidOptionalNamed();
  testNativeFunctionSignatureInvalidOptionalPositional();
}

typedef Int8UnOp = ffi.Int8 Function(ffi.Int8);
typedef IntUnOp = int Function(int);

void testGetGeneric() {
  int generic(ffi.Pointer p) {
    int result;
    result = p.load<int>(); //# 20: compile-time error
    return result;
  }

  ffi.Pointer<ffi.Int8> p = Pointer.allocate();
  p.store(123);
  ffi.Pointer loseType = p;
  generic(loseType);
  p.free();
}

void testGetGeneric2() {
  T generic<T extends Object>() {
    Pointer<ffi.Int8> p = Pointer.allocate();
    p.store(123);
    T result;
    result = p.load<T>(); //# 21: compile-time error
    p.free();
    return result;
  }

  generic<int>();
}

void testGetVoid() {
  ffi.Pointer<ffi.IntPtr> p1 = Pointer.allocate();
  ffi.Pointer<ffi.Void> p2 = p1.cast();

  p2.load<int>(); //# 22: compile-time error

  p1.free();
}

void testGetNativeFunction() {
  Pointer<ffi.NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = p.load(); //# 23: compile-time error
}

void testGetNativeType() {
  // Is it possible to obtain a ffi.Pointer<ffi.NativeType> at all?
}

void testGetTypeMismatch() {
  ffi.Pointer<ffi.Pointer<ffi.Int16>> p = Pointer.allocate();
  ffi.Pointer<ffi.Int16> typedNull = ffi.nullptr.cast();
  p.store(typedNull);

  // this fails to compile due to type mismatch
  ffi.Pointer<ffi.Int8> p2 = p.load(); //# 25: compile-time error

  p.free();
}

void testSetGeneric() {
  void generic(ffi.Pointer p) {
    p.store(123); //# 26: compile-time error
  }

  ffi.Pointer<ffi.Int8> p = Pointer.allocate();
  p.store(123);
  ffi.Pointer loseType = p;
  generic(loseType);
  p.free();
}

void testSetGeneric2() {
  void generic<T extends Object>(T arg) {
    ffi.Pointer<ffi.Int8> p = Pointer.allocate();
    p.store(arg); //# 27: compile-time error
    p.free();
  }

  generic<int>(123);
}

void testSetVoid() {
  ffi.Pointer<ffi.IntPtr> p1 = Pointer.allocate();
  ffi.Pointer<ffi.Void> p2 = p1.cast();

  p2.store(1234); //# 28: compile-time error

  p1.free();
}

void testSetNativeFunction() {
  Pointer<ffi.NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = (a) => a + 1;
  p.store(f); //# 29: compile-time error
}

void testSetNativeType() {
  // Is it possible to obtain a ffi.Pointer<ffi.NativeType> at all?
}

void testSetTypeMismatch() {
  // the pointer to pointer types must match up
  ffi.Pointer<ffi.Int8> pHelper = Pointer.allocate();
  pHelper.store(123);

  ffi.Pointer<ffi.Pointer<ffi.Int16>> p = Pointer.allocate();

  // this fails to compile due to type mismatch
  p.store(pHelper); //# 40: compile-time error

  pHelper.free();
  p.free();
}

void testAsFunctionGeneric() {
  T generic<T extends Function>() {
    ffi.Pointer<ffi.NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
    Function f;
    f = p.asFunction<T>(); //# 11: compile-time error
    return f;
  }

  generic<IntUnOp>();
}

void testAsFunctionGeneric2() {
  generic(ffi.Pointer<ffi.NativeFunction> p) {
    Function f;
    f = p.asFunction<IntUnOp>(); //# 12: compile-time error
    return f;
  }

  ffi.Pointer<ffi.NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  generic(p);
}

void testAsFunctionWrongNativeFunctionSignature() {
  ffi.Pointer<ffi.NativeFunction<IntUnOp>> p;
  Function f = p.asFunction<IntUnOp>(); //# 13: compile-time error
}

typedef IntBinOp = int Function(int, int);

void testAsFunctionTypeMismatch() {
  ffi.Pointer<ffi.NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntBinOp f = p.asFunction(); //# 14: compile-time error
}

typedef NativeDoubleUnOp = ffi.Double Function(ffi.Double);
typedef DoubleUnOp = double Function(double);

double myTimesThree(double d) => d * 3;

int myTimesFour(int i) => i * 4;

void testFromFunctionGeneric() {
  ffi.Pointer<ffi.NativeFunction> generic<T extends Function>(T f) {
    ffi.Pointer<ffi.NativeFunction<NativeDoubleUnOp>> result;
    result = ffi.fromFunction(f); //# 70: compile-time error
    return result;
  }

  generic(myTimesThree);
}

void testFromFunctionGeneric2() {
  ffi.Pointer<ffi.NativeFunction<T>> generic<T extends Function>() {
    ffi.Pointer<ffi.NativeFunction<T>> result;
    result = ffi.fromFunction(myTimesThree); //# 71: compile-time error
    return result;
  }

  generic<NativeDoubleUnOp>();
}

void testFromFunctionWrongNativeFunctionSignature() {
  ffi.fromFunction<IntUnOp>(myTimesFour); //# 72: compile-time error
}

void testFromFunctionTypeMismatch() {
  ffi.Pointer<ffi.NativeFunction<NativeDoubleUnOp>> p;
  p = ffi.fromFunction(myTimesFour); //# 73: compile-time error
}

void testFromFunctionClosure() {
  DoubleUnOp someClosure = (double z) => z / 27.0;
  ffi.Pointer<ffi.NativeFunction<NativeDoubleUnOp>> p;
  p = ffi.fromFunction(someClosure); //# 74: compile-time error
}

class X {
  double tearoff(double d) => d / 27.0;
}

DoubleUnOp fld = null;

void testFromFunctionTearOff() {
  fld = X().tearoff;
  ffi.Pointer<ffi.NativeFunction<NativeDoubleUnOp>> p;
  p = ffi.fromFunction(fld); //# 75: compile-time error
}

void testLookupFunctionGeneric() {
  Function generic<T extends Function>() {
    ffi.DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
    Function result;
    result = l.lookupFunction<T, DoubleUnOp>("cos"); //# 15: compile-time error
    return result;
  }

  generic<NativeDoubleUnOp>();
}

void testLookupFunctionGeneric2() {
  Function generic<T extends Function>() {
    ffi.DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
    Function result;
    result = //# 16: compile-time error
        l.lookupFunction<NativeDoubleUnOp, T>("cos"); //# 16: compile-time error
    return result;
  }

  generic<DoubleUnOp>();
}

void testLookupFunctionWrongNativeFunctionSignature() {
  ffi.DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  l.lookupFunction<IntUnOp, IntUnOp>("cos"); //# 17: compile-time error
}

void testLookupFunctionTypeMismatch() {
  ffi.DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  l.lookupFunction<NativeDoubleUnOp, IntUnOp>("cos"); //# 18: compile-time error
}

// TODO(dacoharkes): make the next 4 test compile errors
typedef Invalid1 = int Function(ffi.Int8);
typedef Invalid2 = ffi.Int8 Function(int);
typedef Invalid3 = ffi.Int8 Function({ffi.Int8 named});
typedef Invalid4 = ffi.Int8 Function([ffi.Int8 positional]);

void testNativeFunctionSignatureInvalidReturn() {
  // ffi.Pointer<ffi.NativeFunction<Invalid1>> p = ffi.fromAddress(999);
}

void testNativeFunctionSignatureInvalidParam() {
  // ffi.Pointer<ffi.NativeFunction<Invalid2>> p = ffi.fromAddress(999);
}

void testNativeFunctionSignatureInvalidOptionalNamed() {
  // ffi.Pointer<ffi.NativeFunction<Invalid3>> p = ffi.fromAddress(999);
}

void testNativeFunctionSignatureInvalidOptionalPositional() {
  // ffi.Pointer<ffi.NativeFunction<Invalid4>> p = ffi.fromAddress(999);
}

// error on missing field annotation
class TestStruct extends ffi.Struct<TestStruct> {
  @ffi.Double()
  double x;

  double y; //# 50: compile-time error
}

// Cannot extend structs.
class TestStruct3 extends TestStruct {} //# 52: compile-time error

// error on double annotation
class TestStruct4 extends ffi.Struct<TestStruct4> {
  @ffi.Double()
  @ffi.Double() //# 53: compile-time error
  double z;
}

// error on annotation not matching up
class TestStruct5 extends ffi.Struct<TestStruct5> {
  @ffi.Int64() //# 54: compile-time error
  double z; //# 54: compile-time error
}

// error on annotation not matching up
class TestStruct6 extends ffi.Struct<TestStruct6> {
  @ffi.Void() //# 55: compile-time error
  double z; //# 55: compile-time error
}

// error on annotation not matching up
class TestStruct7 extends ffi.Struct<TestStruct7> {
  @ffi.NativeType() //# 56: compile-time error
  double z; //# 56: compile-time error
}

// error on field initializer on field
class TestStruct8 extends ffi.Struct<TestStruct8> {
  @ffi.Double() //# 57: compile-time error
  double z = 10.0; //# 57: compile-time error
}

// error on field initializer in constructor
class TestStruct9 extends ffi.Struct<TestStruct9> {
  @ffi.Double()
  double z;

  TestStruct9() : z = 0.0 {} //# 58: compile-time error
}

// A struct "C" must extend "Struct<C>", not "Struct<AnythingElse>".
class TestStruct10 extends ffi.Struct<ffi.Int8> {} //# 59: compile-time error

// Struct classes may not be generic.
class TestStruct11<T> extends //# 60: compile-time error
    ffi.Struct<TestStruct11<dynamic>> {} //# 60: compile-time error

// Structs may not appear inside structs (currently, there is no suitable
// annotation).
class TestStruct12 extends ffi.Struct<TestStruct12> {
  @ffi.Pointer //# 61: compile-time error
  TestStruct9 struct; //# 61: compile-time error
}

class DummyAnnotation {
  const DummyAnnotation();
}

// Structs fields may have other annotations.
class TestStruct13 extends ffi.Struct<TestStruct13> {
  @DummyAnnotation()
  @ffi.Double()
  double z;
}

// Cannot extend native types.

class ENativeType extends ffi.NativeType {} //# 90: compile-time error

class EInt8 extends ffi.Int8 {} //# 91: compile-time error

class EInt16 extends ffi.Int16 {} //# 92: compile-time error

class EInt32 extends ffi.Int32 {} //# 93: compile-time error

class EInt64 extends ffi.Int64 {} //# 94: compile-time error

class EUint8 extends ffi.Uint8 {} //# 95: compile-time error

class EUint16 extends ffi.Uint16 {} //# 96: compile-time error

class EUint32 extends ffi.Uint32 {} //# 97: compile-time error

class EUint64 extends ffi.Uint64 {} //# 98: compile-time error

class EIntPtr extends ffi.IntPtr {} //# 99: compile-time error

class EFloat extends ffi.Float {} //# 910: compile-time error

class EDouble extends ffi.Double {} //# 911: compile-time error

class EVoid extends ffi.Void {} //# 912: compile-time error

class ENativeFunction extends ffi.NativeFunction {} //# 913: compile-time error

class EPointer extends ffi.Pointer {} //# 914: compile-time error

// Cannot implement native natives or Struct.

// Cannot extend native types.

class INativeType implements ffi.NativeType {} //# 80: compile-time error

class IInt8 implements ffi.Int8 {} //# 81: compile-time error

class IInt16 implements ffi.Int16 {} //# 82: compile-time error

class IInt32 implements ffi.Int32 {} //# 83: compile-time error

class IInt64 implements ffi.Int64 {} //# 84: compile-time error

class IUint8 implements ffi.Uint8 {} //# 85: compile-time error

class IUint16 implements ffi.Uint16 {} //# 86: compile-time error

class IUint32 implements ffi.Uint32 {} //# 87: compile-time error

class IUint64 implements ffi.Uint64 {} //# 88: compile-time error

class IIntPtr implements ffi.IntPtr {} //# 88: compile-time error

class IFloat implements ffi.Float {} //# 810: compile-time error

class IDouble implements ffi.Double {} //# 811: compile-time error

class IVoid implements ffi.Void {} //# 812: compile-time error

class INativeFunction //# 813: compile-time error
    implements //# 813: compile-time error
        ffi.NativeFunction {} //# 813: compile-time error

class IPointer implements ffi.Pointer {} //# 814: compile-time error

class IStruct implements ffi.Struct {} //# 815: compile-time error
