// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: camel_case_types

// @dart=2.9

import 'dart:ffi';

/// digest algorithm.
class EVP_MD extends Struct {}

/// digest context.
class EVP_MD_CTX extends Struct {}

/// Type for `void*` used to represent opaque data.
class Data extends Struct {
  static Data fromUint8Pointer(Pointer<Uint8> p) => p.cast<Data>().ref;

  Pointer<Uint8> asUint8Pointer() => addressOf.cast();
}

/// Type for `uint8_t*` used to represent byte data.
class Bytes extends Struct {
  static Data fromUint8Pointer(Pointer<Uint8> p) => p.cast<Data>().ref;

  Pointer<Uint8> asUint8Pointer() => addressOf.cast();
}
