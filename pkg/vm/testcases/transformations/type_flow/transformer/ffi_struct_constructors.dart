// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

/// Retained because of being by-value return type in FFI call.
class Struct1 extends Struct {
  external Pointer notEmpty;
}

/// Retained because of being by-value return type in FFI call.
class Struct2 extends Struct {
  external Pointer notEmpty;
}

/// Retained because of being by-value argument type in FFI callback.
class Struct3 extends Struct {
  external Pointer notEmpty;
}

/// Class not retained, not referenced at all.
class Struct4 extends Struct {
  external Pointer notEmpty;
}

/// Constructor not retained, only referenced as argument type in FFI
/// call but never instantiated in Dart code.
class Struct5 extends Struct {
  external Pointer notEmpty;
}

/// Constructor not retained, only referenced as argument type in FFI
/// call but never instantiated in Dart code.
class Struct6 extends Struct {
  external Pointer notEmpty;
}

/// Constructor not retained, only referenced as return value type in FFI
/// callback but never instantiated in Dart code.
class Struct7 extends Struct {
  external Pointer notEmpty;
}

/// Not retained because of FFI call not being reachable.
class Struct8 extends Struct {
  external Pointer notEmpty;
}

/// Not retained because of FFI call not being reachable.
class Struct9 extends Struct {
  external Pointer notEmpty;
}

/// Not tetained because of FFI callback not being reachable.
class Struct10 extends Struct {
  external Pointer notEmpty;
}

/// Retained by CFE rewrite of load from pointer.
class Struct11 extends Struct {
  external Struct12 nested;
}

/// Retained by rewrite of load from surrounding struct.
class Struct12 extends Struct {
  external Pointer notEmpty;
}

void main() {
  testLookupFunctionReturn();
  testLookupFunctionArgument();
  testAsFunctionReturn();
  testAsFunctionArgument();
  testFromFunctionArgument();
  testFromFunctionReturn();
  testPointerLoad();
  testNestedLoad();
}

/// This forces retaining [Struct1], because it is constructed as return
/// value in the FFI trampoline.
void testLookupFunctionReturn() {
  final dylib = DynamicLibrary.executable();
  final function1 =
      dylib.lookupFunction<Struct1 Function(), Struct1 Function()>('function1');
  final struct1 = function1();
  print(struct1);
}

/// This forces retaining [Struct2], because it is constructed as return
/// value in the FFI trampoline.
void testAsFunctionReturn() {
  final pointer =
      Pointer<NativeFunction<Struct2 Function()>>.fromAddress(0xdeadbeef);
  final function2 = pointer.asFunction<Struct2 Function()>();
  final struct2 = function2();
  print(struct2);
}

int useStruct3(Struct3 struct3) {
  return 42;
}

/// This forces retaining [Struct3], because it is constructed as an argument
/// in the FFI callback.
///
/// We're not doing data-flow analysis to see if this pointer ever makes it to
/// C. We're assuming that all pointers from [fromFunction] calls that are not
/// dead code will be passed to C.
void testFromFunctionArgument() {
  final pointer = Pointer.fromFunction<Int32 Function(Struct3)>(useStruct3, 0);
  print(pointer);
}

void testLookupFunctionArgument() {
  final dylib = DynamicLibrary.executable();
  final function5 =
      dylib.lookupFunction<Void Function(Struct5), void Function(Struct5)>(
          'function5');
  print(function5);
}

void testAsFunctionArgument() {
  final pointer =
      Pointer<NativeFunction<Void Function(Struct6)>>.fromAddress(0xdeadbeef);
  final function6 = pointer.asFunction<void Function(Struct6)>();
  print(function6);
}

Struct7 returnStruct7() {
  throw "I don't want to create a Struct7!";
}

void testFromFunctionReturn() {
  final pointer = Pointer.fromFunction<Struct7 Function()>(returnStruct7);
  print(pointer);
}

/// This does not force retaining [Struct8], because it is not reachable.
void notInvokedLookupFunctionReturn() {
  final dylib = DynamicLibrary.executable();
  final function8 =
      dylib.lookupFunction<Struct8 Function(), Struct8 Function()>('function8');
  final struct8 = function8();
  print(struct8);
}

/// This does not force retaining [Struct9], because it is not reachable.
void notInvokedAsFunctionReturn() {
  final pointer =
      Pointer<NativeFunction<Struct9 Function()>>.fromAddress(0xdeadbeef);
  final function9 = pointer.asFunction<Struct9 Function()>();
  final struct9 = function9();
  print(struct9);
}

int useStruct10(Struct10 struct10) {
  return 42;
}

/// This does not force retaining [Struct10], because it is not reachable.
void notInvokedFromFunctionArgument() {
  final pointer =
      Pointer.fromFunction<Int32 Function(Struct10)>(useStruct10, 0);
  print(pointer);
}

void testPointerLoad() {
  final pointer = Pointer<Struct11>.fromAddress(0xdeadbeef);
  final struct11 = pointer.ref;
  print(struct11);
}

void testNestedLoad() {
  final pointer = Pointer<Struct11>.fromAddress(0xdeadbeef);
  final struct11 = pointer.ref;
  final struct12 = struct11.nested;
  print(struct12);
}
