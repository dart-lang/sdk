// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "dart:_internal" show patch;

@patch
int sizeOf<T extends NativeType>() native "Ffi_sizeOf";

Pointer<T> _allocate<T extends NativeType>(int count) native "Ffi_allocate";

Pointer<T> _fromAddress<T extends NativeType>(int ptr) native "Ffi_fromAddress";

// The real implementation of this function (for interface calls) lives in
// BuildFfiAsFunctionCall in the Kernel frontend. No calls can actually reach
// this function.
DS _asFunctionInternal<DS extends Function, NS extends Function>(
    Pointer<NativeFunction<NS>> ptr) native "Ffi_asFunctionInternal";

@patch
@pragma("vm:entry-point")
class Pointer<T extends NativeType> {
  @patch
  factory Pointer.allocate({int count: 1}) => _allocate<T>(count);

  @patch
  factory Pointer.fromAddress(int ptr) => _fromAddress(ptr);

  @patch
  static Pointer<NativeFunction<T>> fromFunction<T extends Function>(
      @DartRepresentationOf("T") Function f,
      Object exceptionalReturn) native "Ffi_fromFunction";

  // TODO(sjindel): When NNBD is available, we should change `value` to be
  // non-null.
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
  Pointer<U> cast<U extends NativeType>() native "Ffi_cast";

  @patch
  R asFunction<R extends Function>() {
    throw UnsupportedError("Pointer.asFunction cannot be called dynamically.");
  }

  @patch
  void free() native "Ffi_free";
}

// Returns the ABI used for size and alignment calculations.
// See pkg/vm/lib/transformations/ffi.dart.
int _abi()
    native "Recognized method: method is directly interpreted by the bytecode interpreter or IR graph is built in the flow graph builder.";
