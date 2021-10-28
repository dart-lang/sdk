// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for @FfiNative related transformations.

// @dart=2.14

import 'dart:ffi';
import 'dart:nativewrappers';

@FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
external int returnIntPtr(int x);

@FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr', isLeaf: true)
external int returnIntPtrLeaf(int x);

class Classy {
  @FfiNative<IntPtr Function(IntPtr)>('ReturnIntPtr')
  external static int returnIntPtrStatic(int x);
}

class NativeClassy extends NativeFieldWrapperClass1 {
  @FfiNative<Void Function(Pointer<Void>, IntPtr)>('doesntmatter')
  external void goodHasReceiverPointer(int v);

  @FfiNative<Void Function(Handle, IntPtr)>('doesntmatter')
  external void goodHasReceiverHandle(int v);

  @FfiNative<Void Function(Handle, Pointer<Void>)>('doesntmatter')
  external void goodHasReceiverHandleAndPtr(NativeClassy v);

  @FfiNative<Void Function(Handle, Handle)>('doesntmatter')
  external void goodHasReceiverHandleAndHandle(NativeClassy v);

  @FfiNative<Void Function(Pointer<Void>, Handle)>('doesntmatter')
  external void goodHasReceiverPtrAndHandle(NativeClassy v);

  @FfiNative<Handle Function(Pointer<Void>, Bool)>('doesntmatter')
  external String? meh(bool blah);

  @FfiNative<Bool Function(Pointer<Void>)>('doesntmatter')
  external bool blah();
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
}
