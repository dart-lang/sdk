// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: camel_case_types

import 'dart:ffi';

/// digest algorithm.
final class EVP_MD extends Opaque {}

/// digest context.
final class EVP_MD_CTX extends Opaque {}

/// Type for `void*` used to represent opaque data.
final class Data extends Opaque {
  static Pointer<Data> fromUint8Pointer(Pointer<Uint8> p) => p.cast<Data>();
}

extension DataPointerAsUint8Pointer on Pointer<Data> {
  Pointer<Uint8> asUint8Pointer() => cast();
}

/// Type for `uint8_t*` used to represent byte data.
final class Bytes extends Opaque {
  static Pointer<Data> fromUint8Pointer(Pointer<Uint8> p) => p.cast<Data>();
}

extension BytesPointerAsUint8Pointer on Pointer<Bytes> {
  Pointer<Uint8> asUint8Pointer() => cast();
}
