// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch;
import 'dart:_native_typed_data';
import "dart:_internal" show UnmodifiableListBase;

@patch
class ByteData {
  @patch
  factory ByteData(int length) = NativeByteData;
}

@patch
class Float32List {
  @patch
  factory Float32List(int length) = NativeFloat32List;

  @patch
  factory Float32List.fromList(List<double> elements) =
      NativeFloat32List.fromList;
}

@patch
class Float64List {
  @patch
  factory Float64List(int length) = NativeFloat64List;

  @patch
  factory Float64List.fromList(List<double> elements) =
      NativeFloat64List.fromList;
}

@patch
class Int16List {
  @patch
  factory Int16List(int length) = NativeInt16List;

  @patch
  factory Int16List.fromList(List<int> elements) = NativeInt16List.fromList;
}

@patch
class Int32List {
  @patch
  factory Int32List(int length) = NativeInt32List;

  @patch
  factory Int32List.fromList(List<int> elements) = NativeInt32List.fromList;
}

@patch
class Int8List {
  @patch
  factory Int8List(int length) = NativeInt8List;

  @patch
  factory Int8List.fromList(List<int> elements) = NativeInt8List.fromList;
}

@patch
class Uint32List {
  @patch
  factory Uint32List(int length) = NativeUint32List;

  @patch
  factory Uint32List.fromList(List<int> elements) = NativeUint32List.fromList;
}

@patch
class Uint16List {
  @patch
  factory Uint16List(int length) = NativeUint16List;

  @patch
  factory Uint16List.fromList(List<int> elements) = NativeUint16List.fromList;
}

@patch
class Uint8ClampedList {
  @patch
  factory Uint8ClampedList(int length) = NativeUint8ClampedList;

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) =
      NativeUint8ClampedList.fromList;
}

@patch
class Uint8List {
  @patch
  factory Uint8List(int length) = NativeUint8List;

  @patch
  factory Uint8List.fromList(List<int> elements) = NativeUint8List.fromList;
}

@patch
class Int64List {
  @patch
  factory Int64List(int length) {
    throw UnsupportedError("Int64List not supported on the web.");
  }

  @patch
  factory Int64List.fromList(List<int> elements) {
    throw UnsupportedError("Int64List not supported on the web.");
  }
}

@patch
class Uint64List {
  @patch
  factory Uint64List(int length) {
    throw UnsupportedError("Uint64List not supported on the web.");
  }

  @patch
  factory Uint64List.fromList(List<int> elements) {
    throw UnsupportedError("Uint64List not supported on the web.");
  }
}

@patch
class Int32x4List {
  @patch
  factory Int32x4List(int length) = NativeInt32x4List;

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) =
      NativeInt32x4List.fromList;
}

@patch
class Float32x4List {
  @patch
  factory Float32x4List(int length) = NativeFloat32x4List;

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) =
      NativeFloat32x4List.fromList;
}

@patch
class Float64x2List {
  @patch
  factory Float64x2List(int length) = NativeFloat64x2List;

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) =
      NativeFloat64x2List.fromList;
}

@patch
class Float32x4 {
  @patch
  factory Float32x4(double x, double y, double z, double w) = NativeFloat32x4;
  @patch
  factory Float32x4.splat(double v) = NativeFloat32x4.splat;
  @patch
  factory Float32x4.zero() = NativeFloat32x4.zero;
  @patch
  factory Float32x4.fromInt32x4Bits(Int32x4 x) =
      NativeFloat32x4.fromInt32x4Bits;
  @patch
  factory Float32x4.fromFloat64x2(Float64x2 v) = NativeFloat32x4.fromFloat64x2;
}

@patch
class Int32x4 {
  @patch
  factory Int32x4(int x, int y, int z, int w) = NativeInt32x4;
  @patch
  factory Int32x4.bool(bool x, bool y, bool z, bool w) = NativeInt32x4.bool;
  @patch
  factory Int32x4.fromFloat32x4Bits(Float32x4 x) =
      NativeInt32x4.fromFloat32x4Bits;
}

@patch
class Float64x2 {
  @patch
  factory Float64x2(double x, double y) = NativeFloat64x2;
  @patch
  factory Float64x2.splat(double v) = NativeFloat64x2.splat;
  @patch
  factory Float64x2.zero() = NativeFloat64x2.zero;
  @patch
  factory Float64x2.fromFloat32x4(Float32x4 v) = NativeFloat64x2.fromFloat32x4;
}

/// A read-only view of a [ByteBuffer].
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableByteBufferView.
class _UnmodifiableByteBufferView
    implements ByteBuffer, UnmodifiableByteBufferView {
  final ByteBuffer _data;

  _UnmodifiableByteBufferView(ByteBuffer data) : _data = data;

  int get lengthInBytes => _data.lengthInBytes;

  Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableUint8ListView(_data.asUint8List(offsetInBytes, length));

  Int8List asInt8List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableInt8ListView(_data.asInt8List(offsetInBytes, length));

  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableUint8ClampedListView(
          _data.asUint8ClampedList(offsetInBytes, length));

  Uint16List asUint16List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableUint16ListView(_data.asUint16List(offsetInBytes, length));

  Int16List asInt16List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableInt16ListView(_data.asInt16List(offsetInBytes, length));

  Uint32List asUint32List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableUint32ListView(_data.asUint32List(offsetInBytes, length));

  Int32List asInt32List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableInt32ListView(_data.asInt32List(offsetInBytes, length));

  Uint64List asUint64List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableUint64ListView(_data.asUint64List(offsetInBytes, length));

  Int64List asInt64List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableInt64ListView(_data.asInt64List(offsetInBytes, length));

  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableInt32x4ListView(
          _data.asInt32x4List(offsetInBytes, length));

  Float32List asFloat32List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableFloat32ListView(
          _data.asFloat32List(offsetInBytes, length));

  Float64List asFloat64List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableFloat64ListView(
          _data.asFloat64List(offsetInBytes, length));

  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableFloat32x4ListView(
          _data.asFloat32x4List(offsetInBytes, length));

  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableFloat64x2ListView(
          _data.asFloat64x2List(offsetInBytes, length));

  ByteData asByteData([int offsetInBytes = 0, int? length]) =>
      new UnmodifiableByteDataView(_data.asByteData(offsetInBytes, length));
}

/// A read-only view of a [ByteData].
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableByteDataView.
class _UnmodifiableByteDataView implements ByteData, UnmodifiableByteDataView {
  final ByteData _data;

  _UnmodifiableByteDataView(ByteData data) : _data = data;

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

  L _createList(int length);

  L sublist(int start, [int? end]) {
    // NNBD: Spurious error at `end`, `checkValidRange` is legacy.
    int endIndex = RangeError.checkValidRange(start, end!, length);
    int sublistLength = endIndex - start;
    L result = _createList(sublistLength);
    result.setRange(0, sublistLength, _list, start);
    return result;
  }
}

/// View of a [Uint8List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint8ListView.
class _UnmodifiableUint8ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint8List, Uint8List>
    implements UnmodifiableUint8ListView {
  final Uint8List _list;
  _UnmodifiableUint8ListView(Uint8List list) : _list = list;

  Uint8List _createList(int length) => Uint8List(length);
}

/// View of a [Int8List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt8ListView.
class _UnmodifiableInt8ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int8List, Int8List>
    implements UnmodifiableInt8ListView {
  final Int8List _list;
  _UnmodifiableInt8ListView(Int8List list) : _list = list;

  Int8List _createList(int length) => Int8List(length);
}

/// View of a [Uint8ClampedList] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint8ClampedListView.
class _UnmodifiableUint8ClampedListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint8ClampedList, Uint8ClampedList>
    implements UnmodifiableUint8ClampedListView {
  final Uint8ClampedList _list;
  _UnmodifiableUint8ClampedListView(Uint8ClampedList list) : _list = list;

  Uint8ClampedList _createList(int length) => Uint8ClampedList(length);
}

/// View of a [Uint16List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint16ListView.
class _UnmodifiableUint16ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint16List, Uint16List>
    implements UnmodifiableUint16ListView {
  final Uint16List _list;
  _UnmodifiableUint16ListView(Uint16List list) : _list = list;

  Uint16List _createList(int length) => Uint16List(length);
}

/// View of a [Int16List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt16ListView.
class _UnmodifiableInt16ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int16List, Int16List>
    implements UnmodifiableInt16ListView {
  final Int16List _list;
  _UnmodifiableInt16ListView(Int16List list) : _list = list;

  Int16List _createList(int length) => Int16List(length);
}

/// View of a [Uint32List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint32ListView.
class _UnmodifiableUint32ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint32List, Uint32List>
    implements UnmodifiableUint32ListView {
  final Uint32List _list;
  _UnmodifiableUint32ListView(Uint32List list) : _list = list;

  Uint32List _createList(int length) => Uint32List(length);
}

/// View of a [Int32List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt32ListView.
class _UnmodifiableInt32ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int32List, Int32List>
    implements UnmodifiableInt32ListView {
  final Int32List _list;
  _UnmodifiableInt32ListView(Int32List list) : _list = list;

  Int32List _createList(int length) => Int32List(length);
}

/// View of a [Uint64List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableUint64ListView.
class _UnmodifiableUint64ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint64List, Uint64List>
    implements UnmodifiableUint64ListView {
  final Uint64List _list;
  _UnmodifiableUint64ListView(Uint64List list) : _list = list;

  Uint64List _createList(int length) => Uint64List(length);
}

/// View of a [Int64List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt64ListView.
class _UnmodifiableInt64ListView extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int64List, Int64List>
    implements UnmodifiableInt64ListView {
  final Int64List _list;
  _UnmodifiableInt64ListView(Int64List list) : _list = list;

  Int64List _createList(int length) => Int64List(length);
}

/// View of a [Int32x4List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableInt32x4ListView.
class _UnmodifiableInt32x4ListView extends UnmodifiableListBase<Int32x4>
    with _UnmodifiableListMixin<Int32x4, Int32x4List, Int32x4List>
    implements UnmodifiableInt32x4ListView {
  final Int32x4List _list;
  _UnmodifiableInt32x4ListView(Int32x4List list) : _list = list;

  Int32x4List _createList(int length) => Int32x4List(length);
}

/// View of a [Float32x4List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableFloat32x4ListView.
class _UnmodifiableFloat32x4ListView extends UnmodifiableListBase<Float32x4>
    with _UnmodifiableListMixin<Float32x4, Float32x4List, Float32x4List>
    implements UnmodifiableFloat32x4ListView {
  final Float32x4List _list;
  _UnmodifiableFloat32x4ListView(Float32x4List list) : _list = list;

  Float32x4List _createList(int length) => Float32x4List(length);
}

/// View of a [Float64x2List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableFloat64x2ListView.
class _UnmodifiableFloat64x2ListView extends UnmodifiableListBase<Float64x2>
    with _UnmodifiableListMixin<Float64x2, Float64x2List, Float64x2List>
    implements UnmodifiableFloat64x2ListView {
  final Float64x2List _list;
  _UnmodifiableFloat64x2ListView(Float64x2List list) : _list = list;

  Float64x2List _createList(int length) => Float64x2List(length);
}

/// View of a [Float32List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableFloat32ListView.
class _UnmodifiableFloat32ListView extends UnmodifiableListBase<double>
    with _UnmodifiableListMixin<double, Float32List, Float32List>
    implements UnmodifiableFloat32ListView {
  final Float32List _list;
  _UnmodifiableFloat32ListView(Float32List list) : _list = list;

  Float32List _createList(int length) => Float32List(length);
}

/// View of a [Float64List] that disallows modification.
///
/// It is a compile-time error for a class to attempt to extend or implement
/// UnmodifiableFloat64ListView.
class _UnmodifiableFloat64ListView extends UnmodifiableListBase<double>
    with _UnmodifiableListMixin<double, Float64List, Float64List>
    implements UnmodifiableFloat64ListView {
  final Float64List _list;
  _UnmodifiableFloat64ListView(Float64List list) : _list = list;

  Float64List _createList(int length) => Float64List(length);
}

@patch
abstract class UnmodifiableByteBufferView implements Uint8List {
  factory UnmodifiableByteBufferView(ByteBuffer data) =
      _UnmodifiableByteBufferView;
}

@patch
abstract class UnmodifiableByteDataView implements Uint8List {
  factory UnmodifiableByteDataView(ByteData data) = _UnmodifiableByteDataView;
}

@patch
abstract class UnmodifiableUint8ListView implements Uint8List {
  factory UnmodifiableUint8ListView(Uint8List list) =
      _UnmodifiableUint8ListView;
}

@patch
abstract class UnmodifiableInt8ListView implements Int8List {
  factory UnmodifiableInt8ListView(Int8List list) = _UnmodifiableInt8ListView;
}

@patch
abstract class UnmodifiableUint8ClampedListView implements Uint8ClampedList {
  factory UnmodifiableUint8ClampedListView(Uint8ClampedList list) =
      _UnmodifiableUint8ClampedListView;
}

@patch
abstract class UnmodifiableUint16ListView implements Uint16List {
  factory UnmodifiableUint16ListView(Uint16List list) =
      _UnmodifiableUint16ListView;
}

@patch
abstract class UnmodifiableInt16ListView implements Int16List {
  factory UnmodifiableInt16ListView(Int16List list) =
      _UnmodifiableInt16ListView;
}

@patch
abstract class UnmodifiableUint32ListView implements Uint32List {
  factory UnmodifiableUint32ListView(Uint32List list) =
      _UnmodifiableUint32ListView;
}

@patch
abstract class UnmodifiableInt32ListView implements Int32List {
  factory UnmodifiableInt32ListView(Int32List list) =
      _UnmodifiableInt32ListView;
}

@patch
abstract class UnmodifiableUint64ListView implements Uint64List {
  factory UnmodifiableUint64ListView(Uint64List list) =
      _UnmodifiableUint64ListView;
}

@patch
abstract class UnmodifiableInt64ListView implements Int64List {
  factory UnmodifiableInt64ListView(Int64List list) =
      _UnmodifiableInt64ListView;
}

@patch
abstract class UnmodifiableInt32x4ListView implements Int32x4List {
  factory UnmodifiableInt32x4ListView(Int32x4List list) =
      _UnmodifiableInt32x4ListView;
}

@patch
abstract class UnmodifiableFloat32x4ListView implements Float32x4List {
  factory UnmodifiableFloat32x4ListView(Float32x4List list) =
      _UnmodifiableFloat32x4ListView;
}

@patch
abstract class UnmodifiableFloat64x2ListView implements Float64x2List {
  factory UnmodifiableFloat64x2ListView(Float64x2List list) =
      _UnmodifiableFloat64x2ListView;
}

@patch
abstract class UnmodifiableFloat32ListView implements Float32List {
  factory UnmodifiableFloat32ListView(Float32List list) =
      _UnmodifiableFloat32ListView;
}

@patch
abstract class UnmodifiableFloat64ListView implements Float64List {
  factory UnmodifiableFloat64ListView(Float64List list) =
      _UnmodifiableFloat64ListView;
}
