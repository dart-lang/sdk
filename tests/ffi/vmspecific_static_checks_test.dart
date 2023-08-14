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
  testFromFunctionFunctionExceptionValueMustBeConst();
  testNativeCallableGeneric();
  testNativeCallableGeneric2();
  testNativeCallableWrongNativeFunctionSignature();
  testNativeCallableTypeMismatch();
  testNativeCallableClosure();
  testNativeCallableAbstract();
  testNativeCallableMustReturnVoid();
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
  testAllocateNativeType();
  testRefStruct();
  testSizeOfGeneric();
  testSizeOfNativeType();
  testSizeOfHandle();
  testElementAtGeneric();
  testElementAtNativeType();
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
    result = p.value; //# 20: compile-time error
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
    result = p.value; //# 21: compile-time error
    calloc.free(p);
    return result;
  }

  generic<int>();
}

void testGetVoid() {
  Pointer<IntPtr> p1 = calloc();
  Pointer<Void> p2 = p1.cast();

  p2.value; //# 22: compile-time error

  calloc.free(p1);
}

void testGetNativeFunction() {
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = p.value; //# 23: compile-time error
}

void testGetNativeType() {
  // Is it possible to obtain a Pointer<NativeType> at all?
}

void testGetTypeMismatch() {
  Pointer<Pointer<Int16>> p = calloc();
  Pointer<Int16> typedNull = nullptr;
  p.value = typedNull;

  // this fails to compile due to type mismatch
  Pointer<Int8> p2 = p.value; //# 25: compile-time error

  calloc.free(p);
}

void testSetGeneric() {
  void generic(Pointer p) {
    p.value = 123; //# 26: compile-time error
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
    p.value = arg; //# 27: compile-time error
    calloc.free(p);
  }

  generic<int>(123);
}

void testSetVoid() {
  Pointer<IntPtr> p1 = calloc();
  Pointer<Void> p2 = p1.cast();

  p2.value = 1234; //# 28: compile-time error

  calloc.free(p1);
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
  Pointer<Int8> pHelper = calloc();
  pHelper.value = 123;

  Pointer<Pointer<Int16>> p = calloc();

  // this fails to compile due to type mismatch
  p.value = pHelper; //# 40: compile-time error

  calloc.free(pHelper);
  calloc.free(p);
}

void testAsFunctionGeneric() {
  T generic<T extends Function>(T defaultFunction) {
    Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
    T f = defaultFunction;
    f = p.asFunction<T>(); //# 11: compile-time error
    return f;
  }

  generic<IntUnOp>((int a) => a + 1);
}

void testAsFunctionGeneric2() {
  generic(Pointer<NativeFunction> p) {
    Function f = () => "dummy";
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
    Pointer<NativeFunction<NativeDoubleUnOp>> result = nullptr;
    result = Pointer.fromFunction(f); //# 70: compile-time error
    return result;
  }

  generic(myTimesThree);
}

void testFromFunctionGeneric2() {
  Pointer<NativeFunction<T>> generic<T extends Function>() {
    Pointer<NativeFunction<T>> result = nullptr;
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

void testFromFunctionFunctionExceptionValueMustBeConst() {
  final notAConst = 1.1;
  Pointer<NativeFunction<NativeDoubleUnOp>> p;
  p = Pointer.fromFunction(myTimesThree, notAConst); //# 77: compile-time error
}

typedef NativeVoidFunc = Void Function();
typedef VoidFunc = void Function();

void myVoidFunc() { print("Hello World"); }
void myVoidFunc2(int x) { print("x = $x"); }

void testNativeCallableGeneric() {
  NativeCallable? generic<T extends Function>(T f) {
    NativeCallable<NativeVoidFunc>? result;
    result = NativeCallable.listener(f); //# 2100: compile-time error
    return result;
  }

  generic(myVoidFunc);
}

void testNativeCallableGeneric2() {
  NativeCallable<T>? generic<T extends Function>() {
    NativeCallable<T>? result;
    result = NativeCallable.listener(myVoidFunc); //# 2101: compile-time error
    return result;
  }

  generic<NativeVoidFunc>();
}

void testNativeCallableWrongNativeFunctionSignature() {
  NativeCallable<NativeVoidFunc>.listener( //# 2102: compile-time error
      myVoidFunc2); //# 2102: compile-time error
}

void testNativeCallableTypeMismatch() {
  NativeCallable<NativeVoidFunc> p;
  p = NativeCallable.listener(myVoidFunc2); //# 2103: compile-time error
}

void testNativeCallableClosure() {
  VoidFunc someClosure = () => print("Closure");
  NativeCallable<NativeVoidFunc> p;
  p = NativeCallable.listener(someClosure); //# 2104: compile-time error
}

void testNativeCallableAbstract() {
  NativeCallable<Function>.listener(//# 2105: compile-time error
      testNativeCallableAbstract); //# 2105: compile-time error
}

void testNativeCallableMustReturnVoid() {
  NativeCallable<NativeDoubleUnOp>.listener( //# 2106: compile-time error
      myTimesThree); //# 2106: compile-time error
}

void testLookupFunctionGeneric() {
  Function generic<T extends Function>() {
    DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
    Function result = () => "dummy";
    result = l.lookupFunction<T, DoubleUnOp>("cos"); //# 15: compile-time error
    return result;
  }

  generic<NativeDoubleUnOp>();
}

void testLookupFunctionGeneric2() {
  Function generic<T extends Function>() {
    DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
    Function result = () => "dummy";
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

typedef PointervoidN = Void Function(Pointer<void>);
typedef PointervoidD = void Function(Pointer<void>);

void testLookupFunctionPointervoid() {
  DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  // TODO(https://dartbug.com/44593): This should be a compile-time error in CFE.
  // l.lookupFunction<PointervoidN, PointervoidD>("cos");
}

typedef PointerNFdynN = Void Function(Pointer<NativeFunction>);
typedef PointerNFdynD = void Function(Pointer<NativeFunction>);

void testLookupFunctionPointerNFdyn() {
  DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  // TODO(https://dartbug.com/44594): Should this be an error or not?
  // l.lookupFunction<PointerNFdynN, PointerNFdynD>("cos");
}

// error on missing field annotation
final class TestStruct extends Struct {
  @Double()
  external double x;

  external double y; //# 50: compile-time error
}

// Cannot extend structs.
class TestStruct3 extends TestStruct {} //# 52: compile-time error

// error on double annotation
final class TestStruct4 extends Struct {
  @Double()
  @Double() //# 53: compile-time error
  external double z;
}

// error on annotation not matching up
final class TestStruct5 extends Struct {
  @Int64() //# 54: compile-time error
  external double z; //# 54: compile-time error

  external Pointer notEmpty;
}

// error on annotation not matching up
final class TestStruct6 extends Struct {
  @Void() //# 55: compile-time error
  external double z; //# 55: compile-time error

  external Pointer notEmpty;
}

// error on annotation not matching up
final class TestStruct7 extends Struct {
  @NativeType() //# 56: compile-time error
  external double z; //# 56: compile-time error

  external Pointer notEmpty;
}

// error on field initializer on field
final class TestStruct8 extends Struct {
  @Double() //# 57: compile-time error
  double z = 10.0; //# 57: compile-time error

  external Pointer notEmpty;
}

// error on field initializer in constructor
final class TestStruct9 extends Struct {
  @Double() //# 58: compile-time error
  double z; //# 58: compile-time error

  external Pointer notEmpty;

  TestStruct9() : z = 0.0 {} //# 58: compile-time error
}

// Struct classes may not be generic.
class TestStruct11<T> extends //# 60: compile-time error
    Struct<TestStruct11<dynamic>> {} //# 60: compile-time error

// Structs may not appear inside structs (currently, there is no suitable
// annotation).
final class TestStruct12 extends Struct {
  @Pointer //# 61: compile-time error
  external TestStruct9 struct; //# 61: compile-time error

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

class IOpaque implements Opaque {} //# 816: compile-time error

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

final class TestStruct1001 extends Struct {
  external Handle handle; //# 1001: compile-time error

  external Pointer notEmpty;
}

final class TestStruct1002 extends Struct {
  @Handle() //# 1002: compile-time error
  external Object handle; //# 1002: compile-time error

  external Pointer notEmpty;
}

final class EmptyStruct extends Struct {} //# 1099: compile-time error

final class EmptyStruct extends Struct {} //# 1100: compile-time error

void testEmptyStructLookupFunctionArgument() {
  testLibrary.lookupFunction< //# 1100: compile-time error
      Void Function(EmptyStruct), //# 1100: compile-time error
      void Function(EmptyStruct)>("DoesNotExist"); //# 1100: compile-time error
}

final class EmptyStruct extends Struct {} //# 1101: compile-time error

void testEmptyStructLookupFunctionReturn() {
  testLibrary.lookupFunction< //# 1101: compile-time error
      EmptyStruct Function(), //# 1101: compile-time error
      EmptyStruct Function()>("DoesNotExist"); //# 1101: compile-time error
}

final class EmptyStruct extends Struct {} //# 1102: compile-time error

void testEmptyStructAsFunctionArgument() {
  final Pointer< //# 1102: compile-time error
          NativeFunction< //# 1102: compile-time error
              Void Function(EmptyStruct)>> //# 1102: compile-time error
      pointer = Pointer.fromAddress(1234); //# 1102: compile-time error
  pointer.asFunction<void Function(EmptyStruct)>(); //# 1102: compile-time error
}

final class EmptyStruct extends Struct {} //# 1103: compile-time error

void testEmptyStructAsFunctionReturn() {
  final Pointer< //# 1103: compile-time error
          NativeFunction<EmptyStruct Function()>> //# 1103: compile-time error
      pointer = Pointer.fromAddress(1234); //# 1103: compile-time error
  pointer.asFunction<EmptyStruct Function()>(); //# 1103: compile-time error
}

final class EmptyStruct extends Struct {} //# 1104: compile-time error

void _consumeEmptyStruct(EmptyStruct e) => //# 1104: compile-time error
    print(e); //# 1104: compile-time error

void testEmptyStructFromFunctionArgument() {
  Pointer.fromFunction<Void Function(EmptyStruct)>(//# 1104: compile-time error
      _consumeEmptyStruct); //# 1104: compile-time error
}

final class EmptyStruct extends Struct {} //# 1105: compile-time error

EmptyStruct _returnEmptyStruct() => EmptyStruct(); //# 1105: compile-time error

void testEmptyStructFromFunctionReturn() {
  Pointer.fromFunction<EmptyStruct Function()>(//# 1105: compile-time error
      _returnEmptyStruct); //# 1105: compile-time error
}

final class EmptyStruct extends Struct {} //# 1106: compile-time error

final class HasNestedEmptyStruct extends Struct {
  external EmptyStruct nestedEmptyStruct; //# 1106: compile-time error

  external Pointer notEmpty;
}

void testAllocateGeneric() {
  Pointer<T> generic<T extends NativeType>() {
    Pointer<T> pointer = nullptr;
    pointer = calloc(); //# 1320: compile-time error
    return pointer;
  }

  Pointer p = generic<Int64>();
}

void testAllocateNativeType() {
  calloc(); //# 1321: compile-time error
}

void testRefStruct() {
  final myStructPointer = calloc<TestStruct13>();
  Pointer<Struct> structPointer = myStructPointer;
  structPointer.ref; //# 1330: compile-time error
  calloc.free(myStructPointer);
}

T genericRef<T extends Struct>(Pointer<T> p) => //# 1200: compile-time error
    p.ref; //# 1200: compile-time error

T genericRef2<T extends Struct>(Pointer<T> p) => //# 1201: compile-time error
    p.cast<T>().ref; //# 1201: compile-time error

T genericRef3<T extends Struct>(Pointer<T> p) => //# 1202: compile-time error
    p[0]; //# 1202: compile-time error

T genericRef4<T extends Struct>(Array<T> p) => //# 1210: compile-time error
    p[0]; //# 1210: compile-time error

void testSizeOfGeneric() {
  int generic<T extends Pointer>() {
    int size = sizeOf<IntPtr>();
    size = sizeOf<T>(); //# 1300: compile-time error
    return size;
  }

  int size = generic<Pointer<Int64>>();
}

void testSizeOfNativeType() {
  sizeOf(); //# 1301: compile-time error
}

void testSizeOfHandle() {
  sizeOf<Handle>(); //# 1302: compile-time error
}

void testElementAtGeneric() {
  Pointer<T> generic<T extends NativeType>(Pointer<T> pointer) {
    Pointer<T> returnValue = pointer;
    returnValue = returnValue.elementAt(1); //# 1310: compile-time error
    return returnValue;
  }

  Pointer<Int8> p = calloc();
  p.elementAt(1);
  generic(p);
  calloc.free(p);
}

void testElementAtNativeType() {
  Pointer<Int8> p = calloc();
  p.elementAt(1);
  Pointer<NativeType> p2 = p;
  p2.elementAt(1); //# 1311: compile-time error
  calloc.free(p);
}

final class TestStruct1400 extends Struct {
  @Array(8) //# 1400: compile-time error
  @Array(8)
  external Array<Uint8> a0;
}

final class TestStruct1401 extends Struct {
  external Array<Uint8> a0; //# 1401: compile-time error

  external Pointer<Uint8> notEmpty;
}

final class TestStruct1402 extends Struct {
  @Array(8, 8, 8) //# 1402: compile-time error
  external Array<Array<Uint8>> a0; //# 1402: compile-time error

  external Pointer<Uint8> notEmpty;
}

final class TestStruct1403 extends Struct {
  @Array(8, 8) //# 1403: compile-time error
  external Array<Array<Array<Uint8>>> a0; //# 1403: compile-time error

  external Pointer<Uint8> notEmpty;
}

final class TestStruct1404 extends Struct {
  @Array.multi([8, 8, 8]) //# 1404: compile-time error
  external Array<Array<Uint8>> a0; //# 1404: compile-time error

  external Pointer<Uint8> notEmpty;
}

final class TestStruct1405 extends Struct {
  @Array.multi([8, 8]) //# 1405: compile-time error
  external Array<Array<Array<Uint8>>> a0; //# 1405: compile-time error

  external Pointer<Uint8> notEmpty;
}

void testLookupFunctionIsLeafMustBeConst() {
  bool notAConst = false;
  DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  l.lookupFunction< //# 1500: compile-time error
          NativeDoubleUnOp, //# 1500: compile-time error
          DoubleUnOp>("timesFour", //# 1500: compile-time error
      isLeaf: notAConst); //# 1500: compile-time error
}

void testAsFunctionIsLeafMustBeConst() {
  bool notAConst = false;
  Pointer<NativeFunction<Int8UnOp>> p = Pointer.fromAddress(1337);
  IntUnOp f = p.asFunction(isLeaf: notAConst); //# 1501: compile-time error
}

typedef NativeTakesHandle = Void Function(Handle);
typedef TakesHandle = void Function(Object);

void testLookupFunctionTakesHandle() {
  DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  l.lookupFunction< //# 1502: compile-time error
          NativeTakesHandle, //# 1502: compile-time error
          TakesHandle>("takesHandle", //# 1502: compile-time error
      isLeaf: true); //# 1502: compile-time error
}

void testAsFunctionTakesHandle() {
  Pointer<NativeFunction<NativeTakesHandle>> p = //# 1503: compile-time error
      Pointer.fromAddress(1337); //# 1503: compile-time error
  TakesHandle f = p.asFunction(isLeaf: true); //# 1503: compile-time error
}

typedef NativeReturnsHandle = Handle Function();
typedef ReturnsHandle = Object Function();

void testLookupFunctionReturnsHandle() {
  DynamicLibrary l = dlopenPlatformSpecific("ffi_test_dynamic_library");
  l.lookupFunction< //# 1504: compile-time error
          NativeReturnsHandle, //# 1504: compile-time error
          ReturnsHandle>("returnsHandle", //# 1504: compile-time error
      isLeaf: true); //# 1504: compile-time error
}

void testAsFunctionReturnsHandle() {
  Pointer<NativeFunction<NativeReturnsHandle>> p = //# 1505: compile-time error
      Pointer.fromAddress(1337); //# 1505: compile-time error
  ReturnsHandle f = p.asFunction(isLeaf: true); //# 1505: compile-time error
}

@Packed(1)
final class TestStruct1600 extends Struct {
  external Pointer<Uint8> notEmpty;
}

@Packed(1)
@Packed(1) //# 1601: compile-time error
final class TestStruct1601 extends Struct {
  external Pointer<Uint8> notEmpty;
}

@Packed(3) //# 1602: compile-time error
final class TestStruct1602 extends Struct {
  external Pointer<Uint8> notEmpty;
}

@Packed(0) //# 1607: compile-time error
final class TestStruct1607 extends Struct {
  external Pointer<Uint8> notEmpty;
}

final class TestStruct1800 extends Struct {
  external Pointer<Uint8> notEmpty;

  @Array(-1) //# 1800: compile-time error
  external Array<Uint8> inlineArray; //# 1800: compile-time error
}

final class TestStruct1801 extends Struct {
  external Pointer<Uint8> notEmpty;

  @Array(1, -1) //# 1801: compile-time error
  external Array<Uint8> inlineArray; //# 1801: compile-time error
}

final class TestStruct1802 extends Struct {
  external Pointer<Uint8> notEmpty;

  @Array.multi([2, 2, 2, 2, 2, 2, -1]) //# 1802: compile-time error
  external Array<Uint8> inlineArray; //# 1802: compile-time error
}

@AbiSpecificIntegerMapping({
  Abi.androidArm: Uint32(),
  Abi.androidArm64: IntPtr(), //# 1900: compile-time error
  Abi.androidIA32: AbiSpecificInteger1(), //# 1901: compile-time error
})
@AbiSpecificIntegerMapping({}) //# 1902: compile-time error
final class AbiSpecificInteger1 extends AbiSpecificInteger {
  const AbiSpecificInteger1();

  int get a => 4; //# 1910: compile-time error

  external int b; //# 1911: compile-time error
}

class AbiSpecificInteger2
    implements AbiSpecificInteger //# 1903: compile-time error
{
  const AbiSpecificInteger2();
}

class AbiSpecificInteger3
    extends AbiSpecificInteger1 //# 1904: compile-time error
{
  const AbiSpecificInteger3();
}

class AbiSpecificInteger4
    implements AbiSpecificInteger1 //# 1905: compile-time error
{
  const AbiSpecificInteger4();
}

final class MyFinalizableStruct extends Struct
    implements Finalizable //# 2000: compile-time error
{
  external Pointer<Void> field;
}

void testReturnVoidNotVoid() {
  // Taking a more specific argument is okay.
  testLibrary //# 49471: compile-time error
      .lookupFunction< //# 49471: compile-time error
          Handle Function(), //# 49471: compile-time error
          void Function()>("doesntmatter"); //# 49471: compile-time error
}
