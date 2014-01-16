// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Specialized integers and floating point numbers,
 * with SIMD support and efficient lists.
 */
library dart.typed_data;

export 'dart:_native_typed_data' show
  Endianness,
  ByteBuffer,
  TypedData,
  ByteData,
  Float32List,
  Float64List,
  Int8List,
  Int16List,
  Int32List,
  Int64List,
  Uint8ClampedList,
  Uint8List,
  Uint16List,
  Uint32List,
  Uint64List,

  Float32x4,
  Float32x4List,
  Int32x4,
  Int32x4List;
