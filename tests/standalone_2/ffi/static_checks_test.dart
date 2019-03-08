// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing dart:ffi extra checks

library FfiTest;

import 'dart:ffi' as ffi;

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

  ffi.Pointer<ffi.Int8> p = ffi.allocate();
  p.store(123);
  ffi.Pointer loseType = p;
  generic(loseType);
  p.free();
}

void testGetGeneric2() {
  T generic<T extends Object>() {
    ffi.Pointer<ffi.Int8> p = ffi.allocate();
    p.store(123);
    T result;
    result = p.load<T>(); //# 21: compile-time error
    p.free();
    return result;
  }

  generic<int>();
}

void testGetVoid() {
  ffi.Pointer<ffi.IntPtr> p1 = ffi.allocate();
  ffi.Pointer<ffi.Void> p2 = p1.cast();

  p2.load<int>(); //# 22: compile-time error

  p1.free();
}

void testGetNativeFunction() {
  ffi.Pointer<ffi.NativeFunction<Int8UnOp>> p = ffi.fromAddress(1337);
  IntUnOp f = p.load(); //# 23: compile-time error
}

void testGetNativeType() {
  // Is it possible to obtain a ffi.Pointer<ffi.NativeType> at all?
}

void testGetTypeMismatch() {
  ffi.Pointer<ffi.Pointer<ffi.Int16>> p = ffi.allocate();
  ffi.Pointer<ffi.Int16> typedNull = null;
  p.store(typedNull);

  // this fails to compile due to type mismatch
  ffi.Pointer<ffi.Int8> p2 = p.load(); //# 25: compile-time error

  p.free();
}

void testSetGeneric() {
  void generic(ffi.Pointer p) {
    p.store(123); //# 26: compile-time error
  }

  ffi.Pointer<ffi.Int8> p = ffi.allocate();
  p.store(123);
  ffi.Pointer loseType = p;
  generic(loseType);
  p.free();
}

void testSetGeneric2() {
  void generic<T extends Object>(T arg) {
    ffi.Pointer<ffi.Int8> p = ffi.allocate();
    p.store(arg); //# 27: compile-time error
    p.free();
  }

  generic<int>(123);
}

void testSetVoid() {
  ffi.Pointer<ffi.IntPtr> p1 = ffi.allocate();
  ffi.Pointer<ffi.Void> p2 = p1.cast();

  p2.store(1234); //# 28: compile-time error

  p1.free();
}

void testSetNativeFunction() {
  ffi.Pointer<ffi.NativeFunction<Int8UnOp>> p = ffi.fromAddress(1337);
  IntUnOp f = (a) => a + 1;
  p.store(f); //# 29: compile-time error
}

void testSetNativeType() {
  // Is it possible to obtain a ffi.Pointer<ffi.NativeType> at all?
}

void testSetTypeMismatch() {
  // the pointer to pointer types must match up
  ffi.Pointer<ffi.Int8> pHelper = ffi.allocate();
  pHelper.store(123);

  ffi.Pointer<ffi.Pointer<ffi.Int16>> p = ffi.allocate();

  // this fails to compile due to type mismatch
  p.store(pHelper); //# 40: compile-time error

  pHelper.free();
  p.free();
}

void testAsFunctionGeneric() {
  T generic<T extends Function>() {
    ffi.Pointer<ffi.NativeFunction<Int8UnOp>> p = ffi.fromAddress(1337);
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

  ffi.Pointer<ffi.NativeFunction<Int8UnOp>> p = ffi.fromAddress(1337);
  generic(p);
}

void testAsFunctionWrongNativeFunctionSignature() {
  ffi.Pointer<ffi.NativeFunction<IntUnOp>> p;
  Function f = p.asFunction<IntUnOp>(); //# 13: compile-time error
}

typedef IntBinOp = int Function(int, int);

void testAsFunctionTypeMismatch() {
  ffi.Pointer<ffi.NativeFunction<Int8UnOp>> p = ffi.fromAddress(1337);
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
@ffi.struct
class TestStruct extends ffi.Pointer<ffi.Void> {
  @ffi.Double()
  double x;

  double y; //# 50: compile-time error
}

// error on missing struct annotation
class TestStruct2 extends ffi.Pointer<ffi.Void> {
  @ffi.Double() //# 51: compile-time error
  double x; //# 51: compile-time error
}

// error on missing annotation on subtype
@ffi.struct
class TestStruct3 extends TestStruct {
  double z; //# 52: compile-time error
}

// error on double annotation
@ffi.struct
class TestStruct4 extends ffi.Pointer<ffi.Void> {
  @ffi.Double()
  @ffi.Double() //# 53: compile-time error
  double z;
}

// error on annotation not matching up
@ffi.struct
class TestStruct5 extends ffi.Pointer<ffi.Void> {
  @ffi.Int64() //# 54: compile-time error
  double z; //# 54: compile-time error
}

// error on annotation not matching up
@ffi.struct
class TestStruct6 extends ffi.Pointer<ffi.Void> {
  @ffi.Void() //# 55: compile-time error
  double z; //# 55: compile-time error
}

// error on annotation not matching up
@ffi.struct
class TestStruct7 extends ffi.Pointer<ffi.Void> {
  @ffi.NativeType() //# 56: compile-time error
  double z; //# 56: compile-time error
}

// error on field initializer on field
@ffi.struct
class TestStruct8 extends ffi.Pointer<ffi.Void> {
  @ffi.Double() //# 57: compile-time error
  double z = 10.0; //# 57: compile-time error
}

// error on field initializer in constructor
@ffi.struct
class TestStruct9 extends ffi.Pointer<ffi.Void> {
  @ffi.Double()
  double z;

  TestStruct9() : z = 0.0 {} //# 58: compile-time error
}
