// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for @Native related transformations.

// ignore_for_file: deprecated_member_use

// @dart=2.14

import 'dart:ffi';
import 'dart:nativewrappers';

@Native<IntPtr Function(IntPtr)>(symbol: 'ReturnIntPtr')
external int returnIntPtr(int x);

@Native<IntPtr Function(IntPtr)>(symbol: 'ReturnIntPtr', isLeaf: true)
external int returnIntPtrLeaf(int x);

@Native<IntPtr Function(IntPtr)>(isLeaf: true)
external int returnNativeIntPtrLeaf(int x);

class Classy {
  @Native<IntPtr Function(IntPtr)>(symbol: 'ReturnIntPtr')
  external static int returnIntPtrStatic(int x);
}

class NativeClassy extends NativeFieldWrapperClass1 {
  @Native<Void Function(Pointer<Void>, IntPtr)>(symbol: 'doesntmatter')
  external void goodHasReceiverPointer(int v);

  @Native<Void Function(Handle, IntPtr)>(symbol: 'doesntmatter')
  external void goodHasReceiverHandle(int v);

  @Native<Void Function(Handle, Pointer<Void>)>(symbol: 'doesntmatter')
  external void goodHasReceiverHandleAndPtr(NativeClassy v);

  @Native<Void Function(Handle, Handle)>(symbol: 'doesntmatter')
  external void goodHasReceiverHandleAndHandle(NativeClassy v);

  @Native<Void Function(Pointer<Void>, Handle)>(symbol: 'doesntmatter')
  external void goodHasReceiverPtrAndHandle(NativeClassy v);

  @Native<Handle Function(Pointer<Void>, Bool)>(symbol: 'doesntmatter')
  external String? meh(bool blah);

  @Native<Bool Function(Pointer<Void>)>(symbol: 'doesntmatter')
  external bool blah();

  @Native<Bool Function(Pointer<Void>)>(symbol: 'doesntmatter', isLeaf: true)
  external bool get myField;

  @Native<Void Function(Pointer<Void>, Bool)>(
      symbol: 'doesntmatter', isLeaf: true)
  external set myField(bool value);
}

void main() {
  returnIntPtr(13);
  returnIntPtrLeaf(37);
  Classy.returnIntPtrStatic(0xDE);
  NativeClassy().goodHasReceiverPointer(0xAF);
  NativeClassy().goodHasReceiverHandle(0xAF);
  NativeClassy().goodHasReceiverHandleAndPtr(NativeClassy());
  NativeClassy().goodHasReceiverHandleAndHandle(NativeClassy());
  NativeClassy().goodHasReceiverPtrAndHandle(NativeClassy());
  NativeClassy().meh(true);
  NativeClassy().blah();
  final b = NativeClassy().myField;
  NativeClassy().myField = !b;

  Native.addressOf<NativeFunction<IntPtr Function(IntPtr)>>(returnIntPtr);
}
