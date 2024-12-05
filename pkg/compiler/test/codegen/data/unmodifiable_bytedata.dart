// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_foreign_helper' show ArrayFlags, HArrayFlagsSet;

import 'dart:typed_data' show ByteData, Endian;

@pragma('dart2js:never-inline')
/*member: returnUnmodifiable:function() {
  var a = new DataView(new ArrayBuffer(10));
  a.$flags = 3;
  return a;
}*/
returnUnmodifiable() {
  final a = ByteData(10);
  ByteData b = HArrayFlagsSet(a, ArrayFlags.unmodifiable);
  return b;
}

// Two writes, neither checked.
@pragma('dart2js:never-inline')
/*member: returnModifiable1:function() {
  var data = new DataView(new ArrayBuffer(10));
  data.setInt16(0, 200, false);
  data.setInt32(4, 200, false);
  return data;
}*/
returnModifiable1() {
  final data = ByteData(10);
  data.setInt16(0, 200);
  data.setInt32(4, 200);
  return data;
}

// Two writes, neither checked.
@pragma('dart2js:never-inline')
/*member: returnModifiable2:function() {
  var data = new DataView(new ArrayBuffer(10));
  data.setInt16(0, 200, false);
  data.setInt32(4, 200, false);
  return data;
}*/
returnModifiable2() {
  final data = ByteData(10);
  data.setInt16(0, 200);
  data.setInt32(4, 200);
  return data;
}

@pragma('dart2js:never-inline')
/*member: guaranteedFail:function() {
  var a = new DataView(new ArrayBuffer(10));
  a.$flags = 3;
  A.throwUnsupportedOperation(a, 8);
  a.setInt32(0, 100, false);
  a.setUint32(4, 2000, false);
  return a;
}*/
guaranteedFail() {
  final a = ByteData(10);
  ByteData b = HArrayFlagsSet(a, ArrayFlags.unmodifiable);
  b.setInt32(0, 100);
  b.setUint32(4, 2000);
  return b;
}

@pragma('dart2js:never-inline')
/*member: multipleWrites:function(data) {
  data.$flags & 2 && A.throwUnsupportedOperation(data, 13);
  data.setFloat64(0, 1.23, false);
  data.setFloat32(8, 1.23, false);
  return data;
}*/
multipleWrites(ByteData data) {
  // there should only be one write check.
  data.setFloat64(0, 1.23);
  data.setFloat32(8, 1.23);
  return data;
}

@pragma('dart2js:never-inline')
/*member: hoistedLoad:function(data) {
  var t1, i;
  for (t1 = data.$flags | 0, i = 0; i < data.byteLength; i += 2) {
    t1 & 2 && A.throwUnsupportedOperation(data, 10);
    data.setUint16(i, 100, true);
  }
  return data;
}*/
ByteData hoistedLoad(ByteData data) {
  // The load of the flags is hoisted, but the check is not.
  for (int i = 0; i < data.lengthInBytes; i += 2) {
    data.setUint16(i, 100, Endian.little);
  }
  return data;
}

@pragma('dart2js:never-inline')
/*member: maybeUnmodifiable:ignore*/
ByteData maybeUnmodifiable() {
  var data = ByteData(100);
  if (DateTime.now().millisecondsSinceEpoch == 42) {
    data = data.asUnmodifiableView();
  }
  return data;
}

/*member: main:ignore*/
main() {
  print(returnUnmodifiable());
  print(returnModifiable1());
  print(returnModifiable2());
  print(guaranteedFail);
  print(multipleWrites(maybeUnmodifiable()));
  print(hoistedLoad(maybeUnmodifiable()));
}
