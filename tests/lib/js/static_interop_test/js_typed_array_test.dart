// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that JS backed typed data classes behaves correctly.

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:expect/expect.dart';

const isJSBackend = const bool.fromEnvironment('dart.library.html');

// We run many tests in three configurations:
// 1) Test should ensure receivers
//    for all [TypedData] operations will be `JSTypedArrayImpl`.
// 2) Test should ensure arguments to all [TypedData] operations will be
//    `JSTypedDataImpl`.
// 3) Test should ensure both receivers and arguments for all [TypedData]
//    operations will be `JSTypedDataImpl`.
enum TestMode {
  jsReceiver,
  jsArgument,
  jsReceiverAndArguments,
}

enum Position {
  jsReceiver,
  jsArgument,
}

bool useJSType(Position pos, TestMode mode) =>
    (pos == Position.jsReceiver &&
        (mode == TestMode.jsReceiver ||
            mode == TestMode.jsReceiverAndArguments)) ||
    (pos == Position.jsArgument &&
        (mode == TestMode.jsArgument ||
            mode == TestMode.jsReceiverAndArguments));

void uint8ArrayBasicTest(TestMode mode) {
  Uint8List getUint8ListFromList(Position position, List<int> l) {
    final o = Uint8List.fromList(l);
    return useJSType(position, mode) ? o.toJS.toDart : o;
  }

  Uint8List rList(List<int> l) => getUint8ListFromList(Position.jsReceiver, l);
  Uint8List aList(List<int> l) => getUint8ListFromList(Position.jsArgument, l);

  final control = Uint8List.fromList([1, 2]);
  final rl = rList([1, 2]);
  Expect.equals(control.elementSizeInBytes, rl.elementSizeInBytes);
  Expect.equals(control.offsetInBytes, rl.offsetInBytes);
  Expect.equals(control.lengthInBytes, rl.lengthInBytes);

  final al = aList([3, 4]);
  Expect.listEquals([1, 2], rl);
  Expect.listEquals([1, 2, 3, 4], rl + al);
  Expect.listEquals(control, rl.buffer.asUint8List());
}

void initialize(List<int> l) {
  for (var i = 0; i < l.length; i++) {
    l[i] = i + 1;
  }
}

void uint8ArraySetRangeTest() {
  final backingStore = Uint8List(9).toJS.toDart;
  final buffer = backingStore.buffer;
  Expect.equals(buffer.lengthInBytes, backingStore.lengthInBytes);
  final a1 = Uint8List.view(buffer, 0, 7);
  final a2 = Uint8List.view(buffer, 2 * backingStore.elementSizeInBytes, 7);

  initialize(backingStore);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9]', '$backingStore');
  Expect.equals('[1, 2, 3, 4, 5, 6, 7]', '$a1');
  Expect.equals('[3, 4, 5, 6, 7, 8, 9]', '$a2');

  initialize(backingStore);
  a1.setRange(0, 7, a2);
  Expect.equals('[3, 4, 5, 6, 7, 8, 9, 8, 9]', '$backingStore');

  initialize(backingStore);
  a2.setRange(0, 7, a1);
  Expect.equals('[1, 2, 1, 2, 3, 4, 5, 6, 7]', '$backingStore');

  initialize(backingStore);
  a1.setRange(1, 7, a2);
  Expect.equals('[1, 3, 4, 5, 6, 7, 8, 8, 9]', '$backingStore');

  initialize(backingStore);
  a2.setRange(1, 7, a1);
  Expect.equals('[1, 2, 3, 1, 2, 3, 4, 5, 6]', '$backingStore');

  initialize(backingStore);
  a1.setRange(0, 6, a2, 1);
  Expect.equals('[4, 5, 6, 7, 8, 9, 7, 8, 9]', '$backingStore');

  initialize(backingStore);
  a2.setRange(0, 6, a1, 1);
  Expect.equals('[1, 2, 2, 3, 4, 5, 6, 7, 9]', '$backingStore');
}

void arrayBufferTest() {
  final backingStore = Uint8List(12).toJS.toDart;
  final buffer = backingStore.buffer;
  final byteDataView1 = ByteData.view(buffer);
  final byteDataView2 = ByteData.view(buffer, 1, 8);

  Expect.equals(0, byteDataView1.getUint8(0));
  Expect.equals(0, byteDataView1.getUint8(1));
  Expect.equals(12, byteDataView1.lengthInBytes);
  Expect.equals(0, byteDataView1.offsetInBytes);
  Expect.equals(8, byteDataView2.lengthInBytes);
  Expect.equals(1, byteDataView2.offsetInBytes);

  byteDataView1.setUint8(0, 5);
  Expect.equals(5, byteDataView1.getUint8(0));
  Expect.equals(0, byteDataView2.getUint8(0));
  Expect.equals(5, backingStore[0]);

  byteDataView1.setInt8(0, -1);
  Expect.equals(-1, byteDataView1.getInt8(0));
  Expect.equals(0, byteDataView2.getInt8(0));
  Expect.equals(255, backingStore[0]);

  byteDataView1.setUint16(0, 512);
  Expect.equals(512, byteDataView1.getUint16(0));
  Expect.equals(2, byteDataView1.getUint16(0, Endian.little));
  Expect.equals(0, byteDataView2.getUint16(0));
  Expect.equals(0, byteDataView2.getUint16(0, Endian.little));
  Expect.equals(2, backingStore[0]);

  byteDataView1.setUint16(0, 512, Endian.little);
  Expect.equals(2, byteDataView1.getUint16(0));
  Expect.equals(512, byteDataView1.getUint16(0, Endian.little));
  Expect.equals(512, byteDataView2.getUint16(0));
  Expect.equals(2, byteDataView2.getUint16(0, Endian.little));
  Expect.equals(0, backingStore[0]);

  byteDataView1.setInt16(0, -512);
  Expect.equals(-512, byteDataView1.getInt16(0));
  Expect.equals(254, byteDataView1.getInt16(0, Endian.little));
  Expect.equals(0, byteDataView2.getInt16(0));
  Expect.equals(0, byteDataView2.getInt16(0, Endian.little));
  Expect.equals(254, backingStore[0]);

  byteDataView1.setInt16(0, -512, Endian.little);
  Expect.equals(254, byteDataView1.getInt16(0));
  Expect.equals(-512, byteDataView1.getInt16(0, Endian.little));
  Expect.equals(-512, byteDataView2.getInt16(0));
  Expect.equals(254, byteDataView2.getInt16(0, Endian.little));
  Expect.equals(0, backingStore[0]);

  byteDataView1.setUint32(0, 2154041);
  Expect.equals(2154041, byteDataView1.getUint32(0));
  Expect.equals(970858496, byteDataView1.getUint32(0, Endian.little));
  Expect.equals(551434496, byteDataView2.getUint32(0));
  Expect.equals(3792416, byteDataView2.getUint32(0, Endian.little));
  Expect.equals(0, backingStore[0]);

  byteDataView1.setUint32(0, 2154041, Endian.little);
  Expect.equals(970858496, byteDataView1.getUint32(0));
  Expect.equals(2154041, byteDataView1.getUint32(0, Endian.little));
  Expect.equals(3726639104, byteDataView2.getUint32(0));
  Expect.equals(8414, byteDataView2.getUint32(0, Endian.little));
  Expect.equals(57, backingStore[0]);

  byteDataView1.setInt32(0, -2154041);
  Expect.equals(-2154041, byteDataView1.getInt32(0));
  Expect.equals(-954081281, byteDataView1.getInt32(0, Endian.little));
  Expect.equals(-551434496, byteDataView2.getInt32(0));
  Expect.equals(13050335, byteDataView2.getInt32(0, Endian.little));
  Expect.equals(255, backingStore[0]);

  byteDataView1.setInt32(0, -2154041, Endian.little);
  Expect.equals(-954081281, byteDataView1.getInt32(0));
  Expect.equals(-2154041, byteDataView1.getInt32(0, Endian.little));
  Expect.equals(568327936, byteDataView2.getInt32(0));
  Expect.equals(16768801, byteDataView2.getInt32(0, Endian.little));
  Expect.equals(199, backingStore[0]);

  byteDataView1.setFloat32(0, 1.3456789);
  Expect.equals(1.3456789255142212, byteDataView1.getFloat32(0));
  Expect.equals(
      7.140369575608929e-7, byteDataView1.getFloat32(0, Endian.little));
  Expect.equals(-2.7172153416188394e-12, byteDataView2.getFloat32(0));
  Expect.equals(
      4.890122461342029e-39, byteDataView2.getFloat32(0, Endian.little));
  Expect.equals(63, backingStore[0]);

  byteDataView1.setFloat32(0, 1.3456789, Endian.little);
  Expect.equals(7.140369575608929e-7, byteDataView1.getFloat32(0));
  Expect.equals(1.3456789255142212, byteDataView1.getFloat32(0, Endian.little));
  Expect.equals(1.345672607421875, byteDataView2.getFloat32(0));
  Expect.equals(
      5.847426513737849e-39, byteDataView2.getFloat32(0, Endian.little));
  Expect.equals(53, backingStore[0]);

  byteDataView1.setFloat64(0, 1.3456789);
  Expect.equals(1.3456789, byteDataView1.getFloat64(0));
  Expect.equals(
      6.76493079866339e-214, byteDataView1.getFloat64(0, Endian.little));
  Expect.equals(-1.4354837282357192e+258, byteDataView2.getFloat64(0));
  Expect.equals(
      2.736336068096061e-308, byteDataView2.getFloat64(0, Endian.little));
  Expect.equals(63, backingStore[0]);

  byteDataView1.setFloat64(0, 1.3456789, Endian.little);
  Expect.equals(6.76493079866339e-214, byteDataView1.getFloat64(0));
  Expect.equals(1.3456789, byteDataView1.getFloat64(0, Endian.little));
  Expect.equals(-3.4672273430894385e-91, byteDataView2.getFloat64(0));
  Expect.equals(
      1.777784223095324e-307, byteDataView2.getFloat64(0, Endian.little));
  Expect.equals(19, backingStore[0]);
}

void expandContractTest() {
  final b = Int32List(8).toJS.toDart;
  final v = Int8List.view(b.buffer, 12, 8);

  initialize(v);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$v');
  b.setRange(0, 8, v);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$b');

  initialize(b);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$b');
  v.setRange(0, 8, b);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$v');
}

void clampingTest() {
  final a1 = Int8List(8).toJS.toDart;
  final a2 = Uint8ClampedList.view(a1.buffer);

  initialize(a1);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$a1');
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8]', '$a2');
  a1[0] = -1;
  a2.setRange(0, 2, a1);
  Expect.equals('[0, 2, 3, 4, 5, 6, 7, 8]', '$a2');
}

void overlapTest() {
  final buffer = Float32List(3).toJS.toDart.buffer;
  final a0 = Int8List.view(buffer);
  final a1 = Int8List.view(buffer, 1, 5);
  final a2 = Int8List.view(buffer, 2, 5);
  initialize(a0);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]', '$a0');
  Expect.equals('[2, 3, 4, 5, 6]', '$a1');
  Expect.equals('[3, 4, 5, 6, 7]', '$a2');
  a1.setRange(0, 5, a2);
  Expect.equals('[1, 3, 4, 5, 6, 7, 7, 8, 9, 10, 11, 12]', '$a0');

  initialize(a0);
  Expect.equals('[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]', '$a0');
  Expect.equals('[2, 3, 4, 5, 6]', '$a1');
  Expect.equals('[3, 4, 5, 6, 7]', '$a2');
  a2.setRange(0, 5, a1);
  Expect.equals('[1, 2, 2, 3, 4, 5, 6, 8, 9, 10, 11, 12]', '$a0');
}

void testSimd() {
  final a = Uint32List(8).toJS.toDart;
  final si = Int32x4List.view(a.buffer);
  final sf32 = Float32x4List.view(a.buffer);
  final sf64 = Float64x2List.view(a.buffer);

  si[0] = Int32x4(1, 2, 3, 4);
  Expect.equals(1, si[0].x);
  Expect.equals(2, si[0].y);
  Expect.equals(3, si[0].z);
  Expect.equals(4, si[0].w);
  Expect.listEquals([1, 2, 3, 4, 0, 0, 0, 0], a);

  var sia = si.sublist(0, 1);
  Expect.equals(1, sia.length);
  Expect.equals(1, sia[0].x);
  Expect.equals(2, sia[0].y);
  Expect.equals(3, sia[0].z);
  Expect.equals(4, sia[0].w);

  si[1] = Int32x4(5, 6, 7, 8);
  sia = si.sublist(1, 2);
  Expect.listEquals([1, 2, 3, 4, 5, 6, 7, 8], a);
  Expect.equals(5, sia[0].x);
  Expect.equals(6, sia[0].y);
  Expect.equals(7, sia[0].z);
  Expect.equals(8, sia[0].w);

  sf32[0] = Float32x4(1, 2, 3, 4);
  Expect.equals(1, sf32[0].x);
  Expect.equals(2, sf32[0].y);
  Expect.equals(3, sf32[0].z);
  Expect.equals(4, sf32[0].w);
  Expect.listEquals(
      [1065353216, 1073741824, 1077936128, 1082130432, 5, 6, 7, 8], a);

  var sf32a = sf32.sublist(0, 1);
  Expect.equals(1, sf32a.length);
  Expect.equals(1, sf32a[0].x);
  Expect.equals(2, sf32a[0].y);
  Expect.equals(3, sf32a[0].z);
  Expect.equals(4, sf32a[0].w);

  sf32[1] = Float32x4(5, 6, 7, 8);
  sf32a = sf32.sublist(1, 2);
  Expect.listEquals([
    1065353216,
    1073741824,
    1077936128,
    1082130432,
    1084227584,
    1086324736,
    1088421888,
    1090519040
  ], a);
  Expect.equals(5, sf32a[0].x);
  Expect.equals(6, sf32a[0].y);
  Expect.equals(7, sf32a[0].z);
  Expect.equals(8, sf32a[0].w);

  sf64[0] = Float64x2(1, 2);
  Expect.equals(1, sf64[0].x);
  Expect.equals(2, sf64[0].y);
  Expect.listEquals([
    0,
    1072693248,
    0,
    1073741824,
    1084227584,
    1086324736,
    1088421888,
    1090519040
  ], a);

  var sf64a = sf64.sublist(0, 1);
  Expect.equals(1, sf64a.length);
  Expect.equals(1, sf64a[0].x);
  Expect.equals(2, sf64a[0].y);

  sf64[1] = Float64x2(3, 4);
  sf64a = sf64.sublist(1, 2);
  Expect.listEquals(
      [0, 1072693248, 0, 1073741824, 0, 1074266112, 0, 1074790400], a);
  Expect.equals(3, sf64a[0].x);
  Expect.equals(4, sf64a[0].y);
}

void bigTest() {
  if (isJSBackend) {
    // Not yet supported on JS backends.
    return;
  }

  // Uint64List
  {
    final buffer = Uint32List(2).toJS.toDart.buffer;
    final bigList = buffer.asUint64List();
    final littleList = buffer.asUint8List();
    bigList[0] = 4294967296; // Max 32 bit unsigned + 1
    Expect.equals(4294967296, bigList[0]);
    Expect.listEquals([0, 0, 0, 0, 1, 0, 0, 0], littleList);

    final byteData = ByteData.view(buffer);
    byteData.setUint64(0, 4294967297);
    Expect.equals(4294967297, byteData.getUint64(0));
    Expect.listEquals([0, 0, 0, 1, 0, 0, 0, 1], littleList);
  }

  // Int64List
  {
    final buffer = Int32List(2).toJS.toDart.buffer;
    final bigList = buffer.asInt64List();
    final littleList = buffer.asInt8List();
    bigList[0] = -2147483648; // Min 32 bit signed - 1
    Expect.equals(-2147483648, bigList[0]);
    Expect.listEquals([0, 0, 0, -128, -1, -1, -1, -1], littleList);

    final byteData = ByteData.view(buffer);
    byteData.setInt64(0, -2147483649);
    Expect.equals(-2147483649, byteData.getInt64(0));
    Expect.listEquals([-1, -1, -1, -1, 127, -1, -1, -1], littleList);
  }
}

void sublistTest() {
  // Sublists should be copies.
  void listIntTest(List<int> l) {
    l[0] = 1;
    final lSublist = l.sublist(0);
    Expect.equals(1, l[0]);
    Expect.equals(1, lSublist[0]);

    lSublist[0] = 0;
    Expect.equals(1, l[0]);
    Expect.equals(0, lSublist[0]);
  }

  void listDoubleTest(List<double> l) {
    l[0] = 1;
    final lSublist = l.sublist(0);
    Expect.equals(1, l[0]);
    Expect.equals(1, lSublist[0]);

    lSublist[0] = 0;
    Expect.equals(1, l[0]);
    Expect.equals(0, lSublist[0]);
  }

  listIntTest(Uint8List(4).toJS.toDart);
  listIntTest(Uint8ClampedList(4).toJS.toDart);
  listIntTest(Int8List(4).toJS.toDart);
  listIntTest(Uint16List(4).toJS.toDart);
  listIntTest(Int16List(4).toJS.toDart);
  listIntTest(Uint32List(4).toJS.toDart);
  listIntTest(Int32List(4).toJS.toDart);
  listDoubleTest(Float32List(4).toJS.toDart);
  listDoubleTest(Float64List(4).toJS.toDart);

  // Big typed arrays.
  if (isJSBackend) {
    // Not yet supported on JS backends.
    return;
  }
  listIntTest(Uint8List(16).toJS.toDart.buffer.asUint64List());
  listIntTest(Uint8List(16).toJS.toDart.buffer.asInt64List());
}

@JS()
external JSNumber elementSizeInBytes(JSAny a);

@JS()
external void eval(String code);

void elementSizeTest() {
  Expect.equals(elementSizeInBytes(Uint8List(4).toJS).toDartInt, 1);
  Expect.equals(elementSizeInBytes(Uint8ClampedList(4).toJS).toDartInt, 1);
  Expect.equals(elementSizeInBytes(Int8List(4).toJS).toDartInt, 1);
  Expect.equals(elementSizeInBytes(Uint16List(4).toJS).toDartInt, 2);
  Expect.equals(elementSizeInBytes(Int16List(4).toJS).toDartInt, 2);
  Expect.equals(elementSizeInBytes(Uint32List(4).toJS).toDartInt, 4);
  Expect.equals(elementSizeInBytes(Int32List(4).toJS).toDartInt, 4);
  Expect.equals(elementSizeInBytes(Float32List(4).toJS).toDartInt, 4);
  Expect.equals(elementSizeInBytes(Float64List(4).toJS).toDartInt, 8);
}

void main() {
  eval('''
    globalThis.elementSizeInBytes = function(array) {
      return array.BYTES_PER_ELEMENT;
    }
  ''');

  for (final mode in [
    TestMode.jsReceiver,
    TestMode.jsArgument,
    TestMode.jsReceiverAndArguments
  ]) {
    uint8ArrayBasicTest(mode);
  }
  uint8ArraySetRangeTest();
  arrayBufferTest();
  expandContractTest();
  clampingTest();
  overlapTest();
  testSimd();
  bigTest();
  sublistTest();
  elementSizeTest();
}
