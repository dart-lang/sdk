// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.typed_data;

/**
 * A read-only view of a [ByteBuffer].
 */
class UnmodifiableByteBufferView implements ByteBuffer {
  final ByteBuffer _data;

  UnmodifiableByteBufferView(ByteBuffer data) : _data = data;

  int get lengthInBytes => _data.lengthInBytes;

  Uint8List asUint8List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableUint8ListView(_data.asUint8List(offsetInBytes, length));

  Int8List asInt8List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableInt8ListView(_data.asInt8List(offsetInBytes, length));

  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int length]) =>
      new UnmodifiableUint8ClampedListView(
          _data.asUint8ClampedList(offsetInBytes, length));

  Uint16List asUint16List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableUint16ListView(_data.asUint16List(offsetInBytes, length));

  Int16List asInt16List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableInt16ListView(_data.asInt16List(offsetInBytes, length));

  Uint32List asUint32List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableUint32ListView(_data.asUint32List(offsetInBytes, length));

  Int32List asInt32List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableInt32ListView(_data.asInt32List(offsetInBytes, length));

  Uint64List asUint64List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableUint64ListView(_data.asUint64List(offsetInBytes, length));

  Int64List asInt64List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableInt64ListView(_data.asInt64List(offsetInBytes, length));

  Int32x4List asInt32x4List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableInt32x4ListView(
          _data.asInt32x4List(offsetInBytes, length));

  Float32List asFloat32List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableFloat32ListView(
          _data.asFloat32List(offsetInBytes, length));

  Float64List asFloat64List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableFloat64ListView(
          _data.asFloat64List(offsetInBytes, length));

  Float32x4List asFloat32x4List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableFloat32x4ListView(
          _data.asFloat32x4List(offsetInBytes, length));

  Float64x2List asFloat64x2List([int offsetInBytes = 0, int length]) =>
      new UnmodifiableFloat64x2ListView(
          _data.asFloat64x2List(offsetInBytes, length));

  ByteData asByteData([int offsetInBytes = 0, int length]) =>
      new UnmodifiableByteDataView(_data.asByteData(offsetInBytes, length));
}

/**
 * A read-only view of a [ByteData].
 */
class UnmodifiableByteDataView implements ByteData {
  final ByteData _data;

  UnmodifiableByteDataView(ByteData data) : _data = data;

  int getInt8(int byteOffset) => _data.getInt8(byteOffset);

  void setInt8(int byteOffset, int value) => _unsupported();

  int getUint8(int byteOffset) => _data.getUint8(byteOffset);

  void setUint8(int byteOffset, int value) => _unsupported();

  int getInt16(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getInt16(byteOffset, endian);

  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getUint16(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getUint16(byteOffset, endian);

  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getInt32(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getInt32(byteOffset, endian);

  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getUint32(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getUint32(byteOffset, endian);

  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getInt64(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getInt64(byteOffset, endian);

  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  int getUint64(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getUint64(byteOffset, endian);

  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _unsupported();

  double getFloat32(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getFloat32(byteOffset, endian);

  void setFloat32(int byteOffset, double value, [Endian endian = Endian.big]) =>
      _unsupported();

  double getFloat64(int byteOffset, [Endian endian = Endian.big]) =>
      _data.getFloat64(byteOffset, endian);

  void setFloat64(int byteOffset, double value, [Endian endian = Endian.big]) =>
      _unsupported();

  int get elementSizeInBytes => _data.elementSizeInBytes;

  int get offsetInBytes => _data.offsetInBytes;

  int get lengthInBytes => _data.lengthInBytes;

  ByteBuffer get buffer => new UnmodifiableByteBufferView(_data.buffer);

  void _unsupported() {
    throw new UnsupportedError(
        "An UnmodifiableByteDataView may not be modified");
  }
}

abstract class _UnmodifiableListMixin<N, L extends List<N>,
    TD extends TypedData> {
  L get _list;
  TD get _data => (_list as TD);

  int get length => _list.length;

  N operator [](int index) => _list[index];

  int get elementSizeInBytes => _data.elementSizeInBytes;

  int get offsetInBytes => _data.offsetInBytes;

  int get lengthInBytes => _data.lengthInBytes;

  ByteBuffer get buffer => new UnmodifiableByteBufferView(_data.buffer);
}

/**
 * View of a [Uint8List] that disallows modification.
 */
class UnmodifiableUint8ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint8List, Uint8List>
    implements Uint8List {
  final Uint8List _list;
  UnmodifiableUint8ListView(Uint8List list) : _list = list;
}

/**
 * View of a [Int8List] that disallows modification.
 */
class UnmodifiableInt8ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int8List, Int8List>
    implements Int8List {
  final Int8List _list;
  UnmodifiableInt8ListView(Int8List list) : _list = list;
}

/**
 * View of a [Uint8ClampedList] that disallows modification.
 */
class UnmodifiableUint8ClampedListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint8ClampedList, Uint8ClampedList>
    implements Uint8ClampedList {
  final Uint8ClampedList _list;
  UnmodifiableUint8ClampedListView(Uint8ClampedList list) : _list = list;
}

/**
 * View of a [Uint16List] that disallows modification.
 */
class UnmodifiableUint16ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint16List, Uint16List>
    implements Uint16List {
  final Uint16List _list;
  UnmodifiableUint16ListView(Uint16List list) : _list = list;
}

/**
 * View of a [Int16List] that disallows modification.
 */
class UnmodifiableInt16ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int16List, Int16List>
    implements Int16List {
  final Int16List _list;
  UnmodifiableInt16ListView(Int16List list) : _list = list;
}

/**
 * View of a [Uint32List] that disallows modification.
 */
class UnmodifiableUint32ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint32List, Uint32List>
    implements Uint32List {
  final Uint32List _list;
  UnmodifiableUint32ListView(Uint32List list) : _list = list;
}

/**
 * View of a [Int32List] that disallows modification.
 */
class UnmodifiableInt32ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int32List, Int32List>
    implements Int32List {
  final Int32List _list;
  UnmodifiableInt32ListView(Int32List list) : _list = list;
}

/**
 * View of a [Uint64List] that disallows modification.
 */
class UnmodifiableUint64ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint64List, Uint64List>
    implements Uint64List {
  final Uint64List _list;
  UnmodifiableUint64ListView(Uint64List list) : _list = list;
}

/**
 * View of a [Int64List] that disallows modification.
 */
class UnmodifiableInt64ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int64List, Int64List>
    implements Int64List {
  final Int64List _list;
  UnmodifiableInt64ListView(Int64List list) : _list = list;
}

/**
 * View of a [Int32x4List] that disallows modification.
 */
class UnmodifiableInt32x4ListView extends UnmodifiableListBase<Int32x4>
    with _UnmodifiableListMixin<Int32x4, Int32x4List, Int32x4List>
    implements Int32x4List {
  final Int32x4List _list;
  UnmodifiableInt32x4ListView(Int32x4List list) : _list = list;
}

/**
 * View of a [Float32x4List] that disallows modification.
 */
class UnmodifiableFloat32x4ListView extends UnmodifiableListBase<Float32x4>
    with _UnmodifiableListMixin<Float32x4, Float32x4List, Float32x4List>
    implements Float32x4List {
  final Float32x4List _list;
  UnmodifiableFloat32x4ListView(Float32x4List list) : _list = list;
}

/**
 * View of a [Float64x2List] that disallows modification.
 */
class UnmodifiableFloat64x2ListView extends UnmodifiableListBase<Float64x2>
    with _UnmodifiableListMixin<Float64x2, Float64x2List, Float64x2List>
    implements Float64x2List {
  final Float64x2List _list;
  UnmodifiableFloat64x2ListView(Float64x2List list) : _list = list;
}

/**
 * View of a [Float32List] that disallows modification.
 */
class UnmodifiableFloat32ListView extends UnmodifiableListBase<double>
    with _UnmodifiableListMixin<double, Float32List, Float32List>
    implements Float32List {
  final Float32List _list;
  UnmodifiableFloat32ListView(Float32List list) : _list = list;
}

/**
 * View of a [Float64List] that disallows modification.
 */
class UnmodifiableFloat64ListView extends UnmodifiableListBase<double>
    with _UnmodifiableListMixin<double, Float64List, Float64List>
    implements Float64List {
  final Float64List _list;
  UnmodifiableFloat64ListView(Float64List list) : _list = list;
}
