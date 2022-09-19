// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// List of special classes in dart:core that can't be subclassed.
const List<String> denylistedCoreClasses = [
  "bool",
  "int",
  "num",
  "double",
  "String",
  "Null"
];

// List of special classes in dart:typed_data that can't be subclassed.
const List<String> denylistedTypedDataClasses = [
  "ByteBuffer",
  "ByteData",
  "Endian",
  "Float32List",
  "Float32x4",
  "Float32x4List",
  "Float64List",
  "Float64x2",
  "Float64x2List",
  "Int16List",
  "Int32List",
  "Int32x4",
  "Int32x4List",
  "Int64List",
  "Int8List",
  "TypedData",
  "Uint16List",
  "Uint32List",
  "Uint64List",
  "Uint8ClampedList",
  "Uint8List",
  "UnmodifiableByteBufferView",
  "UnmodifiableByteDataView",
  "UnmodifiableFloat32ListView",
  "UnmodifiableFloat32x4ListView",
  "UnmodifiableFloat64ListView",
  "UnmodifiableFloat64x2ListView",
  "UnmodifiableInt16ListView",
  "UnmodifiableInt32ListView",
  "UnmodifiableInt32x4ListView",
  "UnmodifiableInt64ListView",
  "UnmodifiableInt8ListView",
  "UnmodifiableUint16ListView",
  "UnmodifiableUint32ListView",
  "UnmodifiableUint64ListView",
  "UnmodifiableUint8ClampedListView",
  "UnmodifiableUint8ListView",
];
