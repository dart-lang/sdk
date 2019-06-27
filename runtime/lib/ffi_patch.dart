// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

@patch
Pointer<T> allocate<T extends NativeType>({int count: 1}) native "Ffi_allocate";

@patch
T fromAddress<T extends Pointer>(int ptr) native "Ffi_fromAddress";

@patch
int sizeOf<T extends NativeType>() native "Ffi_sizeOf";

@patch
Pointer<NativeFunction<T>> fromFunction<T extends Function>(
    @DartRepresentationOf("T") Function f,
    Object exceptionalReturn) native "Ffi_fromFunction";

@patch
@pragma("vm:entry-point")
class Pointer<T extends NativeType> {
  @patch
  void store(Object value) native "Ffi_store";

  @patch
  R load<R>() native "Ffi_load";

  @patch
  int get address native "Ffi_address";

  // Note this could also be implmented without an extra native as offsetBy
  // (elementSize()*index). This would be 2 native calls rather than one. What
  // would be better?
  @patch
  Pointer<T> elementAt(int index) native "Ffi_elementAt";

  // Note this could also be implmented without an extra  native as
  // fromAddress(address). This would be 2 native calls rather than one.
  // What would be better?
  @patch
  Pointer<T> offsetBy(int offsetInBytes) native "Ffi_offsetBy";

  // Note this could also be implemented without an extra native as
  // fromAddress(address). This would be 2 native calls rather than one.
  // What would be better?
  @patch
  U cast<U extends Pointer>() native "Ffi_cast";

  @patch
  R asFunction<R extends Function>() native "Ffi_asFunction";

  @patch
  void free() native "Ffi_free";
}
