// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Data for a `../codegen_shard*_test.dart` test.

/*member: main:ignore*/
void main() {
  for (var a in [0x123456789, 0, -2]) {
    sink = recognizeMask32(a);
    sink = recognizeMaskToUint32(a);
    sink = recognizeNegativeMaskToUint32(a);
    sink = recognizeAndFromToUnsigned(a);
  }
}

Object? sink;

@pragma('dart2js:noInline')
/*member: recognizeMask32:function(thing) {
  return thing >>> 0;
}*/
int recognizeMask32(int thing) {
  return thing & 0xFFFF_FFFF;
}

@pragma('dart2js:noInline')
/*member: recognizeMaskToUint32:function(thing) {
  return thing >>> 0;
}*/
int recognizeMaskToUint32(int thing) {
  return thing & 0xFFFF_FFFF_FFFF;
}

@pragma('dart2js:noInline')
/*member: recognizeNegativeMaskToUint32:function(thing) {
  return thing >>> 0;
}*/
int recognizeNegativeMaskToUint32(int thing) {
  return thing & -1;
}

@pragma('dart2js:noInline')
/*member: recognizeAndFromToUnsigned:function(thing) {
  return thing >>> 0;
}*/
int recognizeAndFromToUnsigned(int thing) {
  return thing.toUnsigned(32);
}
