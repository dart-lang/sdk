// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show UnmodifiableListBase;
import 'dart:_js_helper' as js;
import 'dart:_js_types';
import 'dart:_string_helper';
import 'dart:_wasm';
import 'dart:typed_data';

/// A read-only view of a [ByteBuffer].
final class _UnmodifiableByteBufferViewImpl implements ByteBuffer {
  final ByteBuffer _data;

  _UnmodifiableByteBufferViewImpl(ByteBuffer data) : _data = data;

  int get lengthInBytes => _data.lengthInBytes;

  Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      _data.asUint8List(offsetInBytes, length).asUnmodifiableView();

  Int8List asInt8List([int offsetInBytes = 0, int? length]) =>
      _data.asInt8List(offsetInBytes, length).asUnmodifiableView();

  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) =>
      _data.asUint8ClampedList(offsetInBytes, length).asUnmodifiableView();

  Uint16List asUint16List([int offsetInBytes = 0, int? length]) =>
      _data.asUint16List(offsetInBytes, length).asUnmodifiableView();

  Int16List asInt16List([int offsetInBytes = 0, int? length]) =>
      _data.asInt16List(offsetInBytes, length).asUnmodifiableView();

  Uint32List asUint32List([int offsetInBytes = 0, int? length]) =>
      _data.asUint32List(offsetInBytes, length).asUnmodifiableView();

  Int32List asInt32List([int offsetInBytes = 0, int? length]) =>
      _data.asInt32List(offsetInBytes, length).asUnmodifiableView();

  Uint64List asUint64List([int offsetInBytes = 0, int? length]) =>
      _data.asUint64List(offsetInBytes, length).asUnmodifiableView();

  Int64List asInt64List([int offsetInBytes = 0, int? length]) =>
      _data.asInt64List(offsetInBytes, length).asUnmodifiableView();

  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) =>
      _data.asInt32x4List(offsetInBytes, length).asUnmodifiableView();

  Float32List asFloat32List([int offsetInBytes = 0, int? length]) =>
      _data.asFloat32List(offsetInBytes, length).asUnmodifiableView();

  Float64List asFloat64List([int offsetInBytes = 0, int? length]) =>
      _data.asFloat64List(offsetInBytes, length).asUnmodifiableView();

  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) =>
      _data.asFloat32x4List(offsetInBytes, length).asUnmodifiableView();

  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) =>
      _data.asFloat64x2List(offsetInBytes, length).asUnmodifiableView();

  ByteData asByteData([int offsetInBytes = 0, int? length]) =>
      _data.asByteData(offsetInBytes, length).asUnmodifiableView();
}

/// A read-only view of a [ByteData].
final class _UnmodifiableByteDataViewImpl implements ByteData {
  final ByteData _data;

  _UnmodifiableByteDataViewImpl(ByteData data) : _data = data;

  @override
  ByteData asUnmodifiableView() => this;

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

  ByteBuffer get buffer => _UnmodifiableByteBufferViewImpl(_data.buffer);

  void _unsupported() =>
      throw UnsupportedError("An UnmodifiableByteDataView may not be modified");
}

mixin _UnmodifiableListMixin<N, L extends List<N>, TD extends TypedData> {
  L get _list;
  TD get _data => (_list as TD);

  int get length => _list.length;

  N operator [](int index) => _list[index];

  int get elementSizeInBytes => _data.elementSizeInBytes;

  int get offsetInBytes => _data.offsetInBytes;

  int get lengthInBytes => _data.lengthInBytes;

  ByteBuffer get buffer => _UnmodifiableByteBufferViewImpl(_data.buffer);

  L createList(int length);

  L sublist(int start, [int? end]) {
    int endIndex = RangeError.checkValidRange(start, end, length);
    int sublistLength = endIndex - start;
    L result = createList(sublistLength);
    result.setRange(0, sublistLength, _list, start);
    return result;
  }
}

/// View of a [Uint8List] that disallows modification.
final class _UnmodifiableUint8ListViewImpl extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint8List, Uint8List>
    implements Uint8List {
  final Uint8List _list;
  _UnmodifiableUint8ListViewImpl(Uint8List list) : _list = list;

  @override
  Uint8List asUnmodifiableView() => this;

  @override
  Uint8List createList(int length) => Uint8List(length);
}

/// View of a [Int8List] that disallows modification.
final class _UnmodifiableInt8ListViewImpl extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int8List, Int8List>
    implements Int8List {
  final Int8List _list;
  _UnmodifiableInt8ListViewImpl(Int8List list) : _list = list;

  @override
  Int8List asUnmodifiableView() => this;

  @override
  Int8List createList(int length) => Int8List(length);
}

/// View of a [Uint8ClampedList] that disallows modification.
final class _UnmodifiableUint8ClampedListViewImpl
    extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint8ClampedList, Uint8ClampedList>
    implements Uint8ClampedList {
  final Uint8ClampedList _list;
  _UnmodifiableUint8ClampedListViewImpl(Uint8ClampedList list) : _list = list;

  @override
  Uint8ClampedList asUnmodifiableView() => this;

  @override
  Uint8ClampedList createList(int length) => Uint8ClampedList(length);
}

/// View of a [Uint16List] that disallows modification.
final class _UnmodifiableUint16ListViewImpl extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint16List, Uint16List>
    implements Uint16List {
  final Uint16List _list;
  _UnmodifiableUint16ListViewImpl(Uint16List list) : _list = list;

  @override
  Uint16List asUnmodifiableView() => this;

  @override
  Uint16List createList(int length) => Uint16List(length);
}

/// View of a [Int16List] that disallows modification.
final class _UnmodifiableInt16ListViewImpl extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int16List, Int16List>
    implements Int16List {
  final Int16List _list;
  _UnmodifiableInt16ListViewImpl(Int16List list) : _list = list;

  @override
  Int16List asUnmodifiableView() => this;

  @override
  Int16List createList(int length) => Int16List(length);
}

/// View of a [Uint32List] that disallows modification.
final class _UnmodifiableUint32ListViewImpl extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint32List, Uint32List>
    implements Uint32List {
  final Uint32List _list;
  _UnmodifiableUint32ListViewImpl(Uint32List list) : _list = list;

  @override
  Uint32List asUnmodifiableView() => this;

  @override
  Uint32List createList(int length) => Uint32List(length);
}

/// View of a [Int32List] that disallows modification.
final class _UnmodifiableInt32ListViewImpl extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int32List, Int32List>
    implements Int32List {
  final Int32List _list;
  _UnmodifiableInt32ListViewImpl(Int32List list) : _list = list;

  @override
  Int32List asUnmodifiableView() => this;

  @override
  Int32List createList(int length) => Int32List(length);
}

/// View of a [Uint64List] that disallows modification.
final class _UnmodifiableUint64ListViewImpl extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Uint64List, Uint64List>
    implements Uint64List {
  final Uint64List _list;
  _UnmodifiableUint64ListViewImpl(Uint64List list) : _list = list;

  @override
  Uint64List asUnmodifiableView() => this;

  @override
  Uint64List createList(int length) => Uint64List(length);
}

/// View of a [Int64List] that disallows modification.
final class _UnmodifiableInt64ListViewImpl extends UnmodifiableListBase<int>
    with _UnmodifiableListMixin<int, Int64List, Int64List>
    implements Int64List {
  final Int64List _list;
  _UnmodifiableInt64ListViewImpl(Int64List list) : _list = list;

  @override
  Int64List asUnmodifiableView() => this;

  @override
  Int64List createList(int length) => Int64List(length);
}

/// View of a [Int32x4List] that disallows modification.
final class _UnmodifiableInt32x4ListViewImpl
    extends UnmodifiableListBase<Int32x4>
    with _UnmodifiableListMixin<Int32x4, Int32x4List, Int32x4List>
    implements Int32x4List {
  final Int32x4List _list;
  _UnmodifiableInt32x4ListViewImpl(Int32x4List list) : _list = list;

  @override
  Int32x4List asUnmodifiableView() => this;

  @override
  Int32x4List createList(int length) => Int32x4List(length);
}

/// View of a [Float32x4List] that disallows modification.
final class _UnmodifiableFloat32x4ListViewImpl
    extends UnmodifiableListBase<Float32x4>
    with _UnmodifiableListMixin<Float32x4, Float32x4List, Float32x4List>
    implements Float32x4List {
  final Float32x4List _list;
  _UnmodifiableFloat32x4ListViewImpl(Float32x4List list) : _list = list;

  @override
  Float32x4List asUnmodifiableView() => this;

  @override
  Float32x4List createList(int length) => Float32x4List(length);
}

/// View of a [Float64x2List] that disallows modification.
final class _UnmodifiableFloat64x2ListViewImpl
    extends UnmodifiableListBase<Float64x2>
    with _UnmodifiableListMixin<Float64x2, Float64x2List, Float64x2List>
    implements Float64x2List {
  final Float64x2List _list;
  _UnmodifiableFloat64x2ListViewImpl(Float64x2List list) : _list = list;

  @override
  Float64x2List asUnmodifiableView() => this;

  @override
  Float64x2List createList(int length) => Float64x2List(length);
}

/// View of a [Float32List] that disallows modification.
final class _UnmodifiableFloat32ListViewImpl
    extends UnmodifiableListBase<double>
    with _UnmodifiableListMixin<double, Float32List, Float32List>
    implements Float32List {
  final Float32List _list;
  _UnmodifiableFloat32ListViewImpl(Float32List list) : _list = list;

  @override
  Float32List asUnmodifiableView() => this;

  @override
  Float32List createList(int length) => Float32List(length);
}

/// View of a [Float64List] that disallows modification.
final class _UnmodifiableFloat64ListViewImpl
    extends UnmodifiableListBase<double>
    with _UnmodifiableListMixin<double, Float64List, Float64List>
    implements Float64List {
  final Float64List _list;
  _UnmodifiableFloat64ListViewImpl(Float64List list) : _list = list;

  @override
  Float64List asUnmodifiableView() => this;

  @override
  Float64List createList(int length) => Float64List(length);
}
