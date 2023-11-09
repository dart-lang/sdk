// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_types;

/// A JS `ArrayBuffer`.
final class JSArrayBufferImpl implements ByteBuffer {
  /// `externref` of a JS `ArrayBuffer`.
  final WasmExternRef? _ref;

  JSArrayBufferImpl.fromRef(this._ref);

  @pragma("wasm:prefer-inline")
  WasmExternRef? get toExternRef => _ref;

  /// Get a JS `DataView` of this `ArrayBuffer`.
  WasmExternRef? view(int offsetInBytes, int? length) =>
      _newDataViewFromArrayBuffer(toExternRef, offsetInBytes, length);

  WasmExternRef? cloneAsDataView(int offsetInBytes, int? lengthInBytes) {
    lengthInBytes ??= this.lengthInBytes;
    return js.JS<WasmExternRef?>('''(o, offsetInBytes, lengthInBytes) => {
      var dst = new ArrayBuffer(lengthInBytes);
      new Uint8Array(dst).set(new Uint8Array(o, offsetInBytes, lengthInBytes));
      return new DataView(dst);
    }''', toExternRef, offsetInBytes.toDouble(), lengthInBytes.toDouble());
  }

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _arrayBufferByteLength(toExternRef);

  @override
  Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      JSUint8ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int8List asInt8List([int offsetInBytes = 0, int? length]) =>
      JSInt8ArrayImpl.view(this, offsetInBytes, length);

  @override
  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) =>
      JSUint8ClampedArrayImpl.view(this, offsetInBytes, length);

  @override
  Uint16List asUint16List([int offsetInBytes = 0, int? length]) =>
      JSUint16ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int16List asInt16List([int offsetInBytes = 0, int? length]) =>
      JSInt16ArrayImpl.view(this, offsetInBytes, length);

  @override
  Uint32List asUint32List([int offsetInBytes = 0, int? length]) =>
      JSUint32ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int32List asInt32List([int offsetInBytes = 0, int? length]) =>
      JSInt32ArrayImpl.view(this, offsetInBytes, length);

  @override
  Uint64List asUint64List([int offsetInBytes = 0, int? length]) =>
      JSBigUint64ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int64List asInt64List([int offsetInBytes = 0, int? length]) =>
      JSBigInt64ArrayImpl.view(this, offsetInBytes, length);

  @override
  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Int32x4List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32x4List.bytesPerElement;
    final storage = JSInt32ArrayImpl.view(this, offsetInBytes, length * 4);
    return JSInt32x4ArrayImpl.externalStorage(storage);
  }

  @override
  Float32List asFloat32List([int offsetInBytes = 0, int? length]) =>
      JSFloat32ArrayImpl.view(this, offsetInBytes, length);

  @override
  Float64List asFloat64List([int offsetInBytes = 0, int? length]) =>
      JSFloat64ArrayImpl.view(this, offsetInBytes, length);

  @override
  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Float32x4List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32x4List.bytesPerElement;
    final storage = JSFloat32ArrayImpl.view(this, offsetInBytes, length * 4);
    return JSFloat32x4ArrayImpl.externalStorage(storage);
  }

  @override
  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Float64x2List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64x2List.bytesPerElement;
    final storage = JSFloat64ArrayImpl.view(this, offsetInBytes, length * 2);
    return JSFloat64x2ArrayImpl.externalStorage(storage);
  }

  @override
  ByteData asByteData([int offsetInBytes = 0, int? length]) =>
      JSDataViewImpl.view(this, offsetInBytes, length);

  @override
  bool operator ==(Object that) =>
      that is JSArrayBufferImpl && js.areEqualInJS(_ref, that._ref);
}

/// Base class for all JS typed array classes.
abstract class JSArrayBase implements TypedData {
  /// `externref` of a JS `DataView`.
  final WasmExternRef? _ref;

  JSArrayBase(this._ref);

  @pragma("wasm:prefer-inline")
  WasmExternRef? get toExternRef => _ref;

  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]);

  @override
  JSArrayBufferImpl get buffer =>
      JSArrayBufferImpl.fromRef(_dataViewBuffer(_ref));

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _dataViewByteLength(toExternRef);

  @override
  @pragma("wasm:prefer-inline")
  int get offsetInBytes => _dataViewByteOffset(_ref);

  @override
  bool operator ==(Object that) =>
      that is JSArrayBase && js.areEqualInJS(_ref, that._ref);
}

/// A JS `DataView`.
final class JSDataViewImpl implements ByteData {
  /// `externref` of a JS `DataView`.
  final WasmExternRef? _ref;

  JSDataViewImpl(int length) : _ref = _newDataView(length);

  JSDataViewImpl.fromRef(this._ref);

  factory JSDataViewImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSDataViewImpl.fromRef(_newDataViewFromArrayBuffer(
          buffer.toExternRef, offsetInBytes, length));

  @pragma("wasm:prefer-inline")
  WasmExternRef? get toExternRef => _ref;

  @override
  JSArrayBufferImpl get buffer =>
      JSArrayBufferImpl.fromRef(_dataViewBuffer(toExternRef));

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _dataViewByteLength(toExternRef);

  @override
  @pragma("wasm:prefer-inline")
  int get offsetInBytes => _dataViewByteOffset(_ref);

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 1;

  @override
  ByteData asUnmodifiableView() => UnmodifiableByteDataView(this);

  @override
  double getFloat32(int byteOffset, [Endian endian = Endian.big]) =>
      _getFloat32(toExternRef, byteOffset, Endian.little == endian);

  @override
  double getFloat64(int byteOffset, [Endian endian = Endian.big]) =>
      _getFloat64(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt16(int byteOffset, [Endian endian = Endian.big]) =>
      _getInt16(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt32(int byteOffset, [Endian endian = Endian.big]) =>
      _getInt32(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt64(int byteOffset, [Endian endian = Endian.big]) =>
      _getBigInt64(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getInt8(int byteOffset) => _getInt8(toExternRef, byteOffset);

  @override
  int getUint16(int byteOffset, [Endian endian = Endian.big]) =>
      _getUint16(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getUint32(int byteOffset, [Endian endian = Endian.big]) =>
      _getUint32(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getUint64(int byteOffset, [Endian endian = Endian.big]) =>
      _getBigUint64(toExternRef, byteOffset, Endian.little == endian);

  @override
  int getUint8(int byteOffset) => _getUint8(toExternRef, byteOffset);

  @override
  void setFloat32(int byteOffset, num value, [Endian endian = Endian.big]) =>
      _setFloat32(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setFloat64(int byteOffset, num value, [Endian endian = Endian.big]) =>
      _setFloat64(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setInt16(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setInt32(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setBigInt64(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setInt8(int byteOffset, int value) =>
      _setInt8(toExternRef, byteOffset, value);

  @override
  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setUint16(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setUint32(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      _setBigUint64(toExternRef, byteOffset, value, Endian.little == endian);

  @override
  void setUint8(int byteOffset, int value) =>
      _setUint8(toExternRef, byteOffset, value);
}

/// Base class for `int` typed lists.
abstract class JSIntArrayImpl extends JSArrayBase
    with ListMixin<int>, FixedLengthListMixin<int> {
  JSIntArrayImpl(super._ref);

  @override
  void setAll(int index, Iterable<int> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<int> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    if (iterable is JSArrayBase) {
      final JSArrayBase source = unsafeCast<JSArrayBase>(iterable);
      final length = end - start;
      final sourceArray = source.toJSArrayExternRef(skipCount, length);
      final targetArray = toJSArrayExternRef(start, length);
      return _setRangeFast(targetArray, sourceArray);
    }

    List<int> otherList = iterable.skip(skipCount).toList(growable: false);

    int count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked operations here.
    for (int i = 0, j = start; i < count; i++, j++) {
      this[j] = otherList[i];
    }
  }
}

final class JSUint8ArrayImpl extends JSIntArrayImpl implements Uint8List {
  JSUint8ArrayImpl._(super._ref);

  factory JSUint8ArrayImpl(int length) =>
      JSUint8ArrayImpl._(_newDataView(length));

  factory JSUint8ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSUint8ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSUint8ArrayImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSUint8ArrayImpl._(buffer.view(offsetInBytes, length));

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 1;

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Uint8Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    _indexCheck(index, length);
    return _getUint8(toExternRef, index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    _indexCheck(index, length);
    _setUint8(toExternRef, index, value);
  }

  @override
  Uint8List asUnmodifiableView() => UnmodifiableUint8ListView(this);

  @override
  Uint8List sublist(int start, [int? end]) {
    final newOffset = offsetInBytes + start;
    final newEnd = RangeError.checkValidRange(newOffset, end, lengthInBytes);
    final newLength = newEnd - newOffset;
    return JSUint8ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSInt8ArrayImpl extends JSIntArrayImpl implements Int8List {
  JSInt8ArrayImpl._(super._ref);

  factory JSInt8ArrayImpl(int length) =>
      JSInt8ArrayImpl._(_newDataView(length));

  factory JSInt8ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSInt8ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSInt8ArrayImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSInt8ArrayImpl._(buffer.view(offsetInBytes, length));

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 1;

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes;

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    _indexCheck(index, length);
    return _getInt8(toExternRef, index);
  }

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Int8Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    _indexCheck(index, length);
    _setInt8(toExternRef, index, value);
  }

  @override
  Int8List asUnmodifiableView() => UnmodifiableInt8ListView(this);

  @override
  Int8List sublist(int start, [int? end]) {
    final newOffset = offsetInBytes + start;
    final newEnd = RangeError.checkValidRange(newOffset, end, lengthInBytes);
    final newLength = newEnd - newOffset;
    return JSInt8ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSUint8ClampedArrayImpl extends JSIntArrayImpl
    implements Uint8ClampedList {
  JSUint8ClampedArrayImpl._(super._ref);

  factory JSUint8ClampedArrayImpl(int length) =>
      JSUint8ClampedArrayImpl._(_newDataView(length));

  factory JSUint8ClampedArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSUint8ClampedArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSUint8ClampedArrayImpl.view(
          JSArrayBufferImpl buffer, int offsetInBytes, int? length) =>
      JSUint8ClampedArrayImpl._(buffer.view(offsetInBytes, length));

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 1;

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Uint8ClampedArray(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    _indexCheck(index, length);
    return _getUint8(toExternRef, index);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    _indexCheck(index, length);
    _setUint8(toExternRef, index, value.clamp(0, 255));
  }

  @override
  Uint8ClampedList asUnmodifiableView() =>
      UnmodifiableUint8ClampedListView(this);

  @override
  Uint8ClampedList sublist(int start, [int? end]) {
    final newOffset = offsetInBytes + start;
    final newEnd = RangeError.checkValidRange(newOffset, end, lengthInBytes);
    final newLength = newEnd - newOffset;
    return JSUint8ClampedArrayImpl._(
        buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSUint16ArrayImpl extends JSIntArrayImpl implements Uint16List {
  JSUint16ArrayImpl._(super._ref);

  factory JSUint16ArrayImpl(int length) =>
      JSUint16ArrayImpl._(_newDataView(length * 2));

  factory JSUint16ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSUint16ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSUint16ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint16List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -2)
        : length * 2);
    return JSUint16ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 2;

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes >>> 1;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Uint16Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 2),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    _indexCheck(index, length);
    return _getUint16(toExternRef, index * 2, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    _indexCheck(index, length);
    _setUint16(toExternRef, index * 2, value, true);
  }

  @override
  Uint16List asUnmodifiableView() => UnmodifiableUint16ListView(this);

  @override
  Uint16List sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 2);
    final int newEnd = end == null ? lengthInBytes : end * 2;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 2, newEnd ~/ 2, lengthInBytes ~/ 2);
    return JSUint16ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSInt16ArrayImpl extends JSIntArrayImpl implements Int16List {
  JSInt16ArrayImpl._(super._ref);

  factory JSInt16ArrayImpl(int length) =>
      JSInt16ArrayImpl._(_newDataView(length * 2));

  factory JSInt16ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSInt16ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSInt16ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int16List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -2)
        : length * 2);
    return JSInt16ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 2;

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes >>> 1;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Int16Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 2),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    _indexCheck(index, length);
    return _getInt16(toExternRef, index * 2, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    _indexCheck(index, length);
    _setInt16(toExternRef, index * 2, value, true);
  }

  @override
  Int16List asUnmodifiableView() => UnmodifiableInt16ListView(this);

  @override
  Int16List sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 2);
    final int newEnd = end == null ? lengthInBytes : end * 2;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 2, newEnd ~/ 2, lengthInBytes ~/ 2);
    return JSInt16ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSUint32ArrayImpl extends JSIntArrayImpl implements Uint32List {
  JSUint32ArrayImpl._(super._ref);

  factory JSUint32ArrayImpl(int length) =>
      JSUint32ArrayImpl._(_newDataView(length * 4));

  factory JSUint32ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSUint32ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSUint32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint32List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -4)
        : length * 4);
    return JSUint32ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 4;

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes >>> 2;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Uint32Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 4),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    _indexCheck(index, length);
    return _getUint32(toExternRef, index * 4, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    _indexCheck(index, length);
    _setUint32(toExternRef, index * 4, value, true);
  }

  @override
  Uint32List asUnmodifiableView() => UnmodifiableUint32ListView(this);

  @override
  Uint32List sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 4);
    final int newEnd = end == null ? lengthInBytes : end * 4;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 4, newEnd ~/ 4, lengthInBytes ~/ 4);
    return JSUint32ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSInt32ArrayImpl extends JSIntArrayImpl implements Int32List {
  JSInt32ArrayImpl._(super._ref);

  factory JSInt32ArrayImpl(int length) =>
      JSInt32ArrayImpl._(_newDataView(length * 4));

  factory JSInt32ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSInt32ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSInt32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int32List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -4)
        : length * 4);
    return JSInt32ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes >>> 2;

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 4;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Int32Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 4),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    _indexCheck(index, length);
    return _getInt32(toExternRef, index * 4, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    _indexCheck(index, length);
    _setInt32(toExternRef, index * 4, value, true);
  }

  @override
  Int32List asUnmodifiableView() => UnmodifiableInt32ListView(this);

  @override
  Int32List sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 4);
    final int newEnd = end == null ? lengthInBytes : end * 4;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 4, newEnd ~/ 4, lengthInBytes ~/ 4);
    return JSInt32ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSInt32x4ArrayImpl
    with ListMixin<Int32x4>, FixedLengthListMixin<Int32x4>
    implements Int32x4List {
  final JSInt32ArrayImpl _storage;

  JSInt32x4ArrayImpl.externalStorage(JSInt32ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Int32x4List.bytesPerElement;

  @override
  @pragma("wasm:prefer-inline")
  int get length => _storage.length ~/ 4;

  @override
  @pragma("wasm:prefer-inline")
  Int32x4 operator [](int index) {
    _indexCheck(index, length);
    int _x = _storage[(index * 4) + 0];
    int _y = _storage[(index * 4) + 1];
    int _z = _storage[(index * 4) + 2];
    int _w = _storage[(index * 4) + 3];
    return Int32x4(_x, _y, _z, _w);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, Int32x4 value) {
    _indexCheck(index, length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  @override
  Int32x4List asUnmodifiableView() => UnmodifiableInt32x4ListView(this);

  @override
  Int32x4List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSInt32x4ArrayImpl.externalStorage(
        _storage.sublist(start * 4, stop * 4) as JSInt32ArrayImpl);
  }

  @override
  void setAll(int index, Iterable<Int32x4> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<Int32x4> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<Int32x4> otherList = iterable.skip(skipCount).toList(growable: false);

    int count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked operations here.
    for (int i = 0, j = start; i < count; i++, j++) {
      this[j] = otherList[i];
    }
  }
}

/// Base class for 64-bit `int` typed lists.
abstract class JSBigIntArrayImpl extends JSIntArrayImpl {
  JSBigIntArrayImpl(super._ref);

  @override
  int get elementSizeInBytes => 8;
}

final class JSBigUint64ArrayImpl extends JSBigIntArrayImpl
    implements Uint64List {
  JSBigUint64ArrayImpl._(super._ref);

  factory JSBigUint64ArrayImpl(int length) =>
      JSBigUint64ArrayImpl._(_newDataView(length * 8));

  factory JSBigUint64ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSBigUint64ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSBigUint64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint64List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -8)
        : length * 8);
    return JSBigUint64ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes >>> 3;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new BigUint64Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 8),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    _indexCheck(index, length);
    return _getBigUint64(toExternRef, index * 8, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    _indexCheck(index, length);
    return _setBigUint64(toExternRef, index * 8, value, true);
  }

  @override
  Uint64List asUnmodifiableView() => UnmodifiableUint64ListView(this);

  @override
  Uint64List sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 8);
    final int newEnd = end == null ? lengthInBytes : end * 8;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 8, newEnd ~/ 8, lengthInBytes ~/ 8);
    return JSBigUint64ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSBigInt64ArrayImpl extends JSBigIntArrayImpl implements Int64List {
  JSBigInt64ArrayImpl._(super._ref);

  factory JSBigInt64ArrayImpl(int length) =>
      JSBigInt64ArrayImpl._(_newDataView(length * 8));

  factory JSBigInt64ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSBigInt64ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSBigInt64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int64List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -8)
        : length * 8);
    return JSBigInt64ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes >>> 3;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new BigInt64Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 8),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  int operator [](int index) {
    _indexCheck(index, length);
    return _getBigInt64(toExternRef, index * 8, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, int value) {
    _indexCheck(index, length);
    _setBigInt64(toExternRef, index * 8, value, true);
  }

  @override
  Int64List asUnmodifiableView() => UnmodifiableInt64ListView(this);

  @override
  Int64List sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 8);
    final int newEnd = end == null ? lengthInBytes : end * 8;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 8, newEnd ~/ 8, lengthInBytes ~/ 8);
    return JSBigInt64ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

/// Base class for `double` typed lists.
abstract class JSFloatArrayImpl extends JSArrayBase
    with ListMixin<double>, FixedLengthListMixin<double> {
  JSFloatArrayImpl(super._ref);

  @override
  void setAll(int index, Iterable<double> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<double> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    if (iterable is JSArrayBase) {
      final JSArrayBase source = unsafeCast<JSArrayBase>(iterable);
      final length = end - start;
      final sourceArray = source.toJSArrayExternRef(skipCount, length);
      final targetArray = toJSArrayExternRef(start, length);
      return _setRangeFast(targetArray, sourceArray);
    }

    List<double> otherList = iterable.skip(skipCount).toList(growable: false);

    int count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked operations here.
    for (int i = 0, j = start; i < count; i++, j++) {
      this[j] = otherList[i];
    }
  }
}

final class JSFloat32ArrayImpl extends JSFloatArrayImpl implements Float32List {
  JSFloat32ArrayImpl._(super._ref);

  factory JSFloat32ArrayImpl(int length) =>
      JSFloat32ArrayImpl._(_newDataView(length * 4));

  factory JSFloat32ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSFloat32ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSFloat32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Float32List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -4)
        : length * 4);
    return JSFloat32ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes >>> 2;

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 4;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Float32Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 4),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  double operator [](int index) {
    _indexCheck(index, length);
    return _getFloat32(toExternRef, index * 4, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, double value) {
    _indexCheck(index, length);
    _setFloat32(toExternRef, index * 4, value, true);
  }

  @override
  Float32List asUnmodifiableView() => UnmodifiableFloat32ListView(this);

  @override
  Float32List sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 4);
    final int newEnd = end == null ? lengthInBytes : end * 4;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 4, newEnd ~/ 4, lengthInBytes ~/ 4);
    return JSFloat32ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSFloat64ArrayImpl extends JSFloatArrayImpl implements Float64List {
  JSFloat64ArrayImpl._(super._ref);

  factory JSFloat64ArrayImpl(int length) =>
      JSFloat64ArrayImpl._(_newDataView(length * 8));

  factory JSFloat64ArrayImpl.fromJSArray(WasmExternRef? jsArrayRef) =>
      JSFloat64ArrayImpl._(_dataViewFromJSArray(jsArrayRef));

  factory JSFloat64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Float64List.bytesPerElement);
    final lengthInBytes = (length == null
        ? ((buffer.lengthInBytes - offsetInBytes) & -8)
        : length * 8);
    return JSFloat64ArrayImpl._(buffer.view(offsetInBytes, lengthInBytes));
  }

  @override
  @pragma("wasm:prefer-inline")
  int get length => lengthInBytes >>> 3;

  @override
  @pragma("wasm:prefer-inline")
  int get elementSizeInBytes => 8;

  @override
  WasmExternRef? toJSArrayExternRef([int start = 0, int? length]) => js.JS<
          WasmExternRef?>(
      '(o, start, length) => new Float64Array(o.buffer, o.byteOffset + start, length)',
      toExternRef,
      WasmI32.fromInt(start * 8),
      WasmI32.fromInt(length ?? (this.length - start)));

  @override
  @pragma("wasm:prefer-inline")
  double operator [](int index) {
    _indexCheck(index, length);
    return _getFloat64(toExternRef, index * 8, true);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, double value) {
    _indexCheck(index, length);
    _setFloat64(toExternRef, index * 8, value, true);
  }

  @override
  Float64List asUnmodifiableView() => UnmodifiableFloat64ListView(this);

  @override
  Float64List sublist(int start, [int? end]) {
    final int newOffset = offsetInBytes + (start * 8);
    final int newEnd = end == null ? lengthInBytes : end * 8;
    final int newLength = newEnd - newOffset;
    RangeError.checkValidRange(newOffset ~/ 8, newEnd ~/ 8, lengthInBytes ~/ 8);
    return JSFloat64ArrayImpl._(buffer.cloneAsDataView(newOffset, newLength));
  }
}

final class JSFloat32x4ArrayImpl
    with ListMixin<Float32x4>, FixedLengthListMixin<Float32x4>
    implements Float32x4List {
  final JSFloat32ArrayImpl _storage;

  JSFloat32x4ArrayImpl.externalStorage(JSFloat32ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Float32x4List.bytesPerElement;

  @override
  @pragma("wasm:prefer-inline")
  int get length => _storage.length ~/ 4;

  @override
  @pragma("wasm:prefer-inline")
  Float32x4 operator [](int index) {
    _indexCheck(index, length);
    double _x = _storage[(index * 4) + 0];
    double _y = _storage[(index * 4) + 1];
    double _z = _storage[(index * 4) + 2];
    double _w = _storage[(index * 4) + 3];
    return Float32x4(_x, _y, _z, _w);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, Float32x4 value) {
    _indexCheck(index, length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  @override
  Float32x4List asUnmodifiableView() => UnmodifiableFloat32x4ListView(this);

  @override
  Float32x4List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat32x4ArrayImpl.externalStorage(
        _storage.sublist(start * 4, stop * 4) as JSFloat32ArrayImpl);
  }

  @override
  void setAll(int index, Iterable<Float32x4> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<Float32x4> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<Float32x4> otherList =
        iterable.skip(skipCount).toList(growable: false);

    int count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked operations here.
    for (int i = 0, j = start; i < count; i++, j++) {
      this[j] = otherList[i];
    }
  }
}

final class JSFloat64x2ArrayImpl
    with ListMixin<Float64x2>, FixedLengthListMixin<Float64x2>
    implements Float64x2List {
  final JSFloat64ArrayImpl _storage;

  JSFloat64x2ArrayImpl.externalStorage(JSFloat64ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  @pragma("wasm:prefer-inline")
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Float64x2List.bytesPerElement;

  @override
  @pragma("wasm:prefer-inline")
  int get length => _storage.length ~/ 2;

  @override
  @pragma("wasm:prefer-inline")
  Float64x2 operator [](int index) {
    _indexCheck(index, length);
    double _x = _storage[(index * 2) + 0];
    double _y = _storage[(index * 2) + 1];
    return Float64x2(_x, _y);
  }

  @override
  @pragma("wasm:prefer-inline")
  void operator []=(int index, Float64x2 value) {
    _indexCheck(index, length);
    _storage[(index * 2) + 0] = value.x;
    _storage[(index * 2) + 1] = value.y;
  }

  @override
  Float64x2List asUnmodifiableView() => UnmodifiableFloat64x2ListView(this);

  @override
  Float64x2List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat64x2ArrayImpl.externalStorage(
        _storage.sublist(start * 2, stop * 2) as JSFloat64ArrayImpl);
  }

  @override
  void setAll(int index, Iterable<Float64x2> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<Float64x2> iterable,
      [int skipCount = 0]) {
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) {
      throw ArgumentError(skipCount);
    }

    List<Float64x2> otherList =
        iterable.skip(skipCount).toList(growable: false);

    int count = end - start;
    if (otherList.length < count) {
      throw IterableElementError.tooFew();
    }

    // TODO(omersa): Use unchecked operations here.
    for (int i = 0, j = start; i < count; i++, j++) {
      this[j] = otherList[i];
    }
  }
}

@pragma("wasm:prefer-inline")
void _indexCheck(int index, int length) {
  if (WasmI64.fromInt(length).leU(WasmI64.fromInt(index))) {
    throw IndexError.withLength(index, length);
  }
}

void _setRangeFast(WasmExternRef? targetArray, WasmExternRef? sourceArray) =>
    js.JS<void>('(t, s) => t.set(s)', targetArray, sourceArray);

void _offsetAlignmentCheck(int offset, int alignment) {
  if ((offset % alignment) != 0) {
    throw new RangeError('Offset ($offset) must be a multiple of '
        'bytesPerElement ($alignment)');
  }
}

WasmExternRef? _newDataView(int length) => js.JS<WasmExternRef?>(
    'l => new DataView(new ArrayBuffer(l))', WasmI32.fromInt(length));

WasmExternRef? _dataViewFromJSArray(WasmExternRef? jsArrayRef) =>
    js.JS<WasmExternRef?>(
        '(o) => new DataView(o.buffer, o.byteOffset, o.byteLength)',
        jsArrayRef);

@pragma("wasm:prefer-inline")
int _arrayBufferByteLength(WasmExternRef? ref) =>
    js.JS<WasmI32>('o => o.byteLength', ref).toIntSigned();

WasmExternRef? _dataViewBuffer(WasmExternRef? dataViewRef) =>
    js.JS<WasmExternRef?>('o => o.buffer', dataViewRef);

@pragma("wasm:prefer-inline")
int _dataViewByteOffset(WasmExternRef? dataViewRef) =>
    js.JS<WasmI32>('o => o.byteOffset', dataViewRef).toIntSigned();

@pragma("wasm:prefer-inline")
int _dataViewByteLength(WasmExternRef? ref) => js
    .JS<WasmF64>(
        "Function.prototype.call.bind(Object.getOwnPropertyDescriptor(DataView.prototype, 'byteLength').get)",
        ref)
    .truncSatS()
    .toInt();

@pragma("wasm:prefer-inline")
WasmExternRef? _newDataViewFromArrayBuffer(
        WasmExternRef? bufferRef, int offsetInBytes, int? length) =>
    length == null
        ? js.JS<WasmExternRef?>('(b, o) => new DataView(b, o)', bufferRef,
            WasmI32.fromInt(offsetInBytes))
        : js.JS<WasmExternRef?>('(b, o, l) => new DataView(b, o, l)', bufferRef,
            WasmI32.fromInt(offsetInBytes), WasmI32.fromInt(length));

@pragma("wasm:prefer-inline")
int _getUint8(WasmExternRef? ref, int byteOffset) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getUint8)',
        ref, WasmI32.fromInt(byteOffset))
    .toIntUnsigned();

@pragma("wasm:prefer-inline")
void _setUint8(WasmExternRef? ref, int byteOffset, int value) => js.JS<void>(
    'Function.prototype.call.bind(DataView.prototype.setUint8)',
    ref,
    WasmI32.fromInt(byteOffset),
    WasmI32.fromInt(value));

@pragma("wasm:prefer-inline")
int _getInt8(WasmExternRef? ref, int byteOffset) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getInt8)',
        ref, WasmI32.fromInt(byteOffset))
    .toIntSigned();

@pragma("wasm:prefer-inline")
void _setInt8(WasmExternRef? ref, int byteOffset, int value) => js.JS<void>(
    'Function.prototype.call.bind(DataView.prototype.setInt8)',
    ref,
    WasmI32.fromInt(byteOffset),
    WasmI32.fromInt(value));

@pragma("wasm:prefer-inline")
int _getUint16(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getUint16)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toIntUnsigned();

@pragma("wasm:prefer-inline")
void _setUint16(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setUint16)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getInt16(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getInt16)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toIntSigned();

@pragma("wasm:prefer-inline")
void _setInt16(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setInt16)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getUint32(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getUint32)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toIntUnsigned();

@pragma("wasm:prefer-inline")
void _setUint32(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setUint32)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getInt32(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI32>('Function.prototype.call.bind(DataView.prototype.getInt32)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toIntSigned();

@pragma("wasm:prefer-inline")
void _setInt32(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setInt32)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getBigUint64(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI64>(
        'Function.prototype.call.bind(DataView.prototype.getBigUint64)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI32.fromBool(littleEndian))
    .toInt();

@pragma("wasm:prefer-inline")
void _setBigUint64(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setBigUint64)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI64.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
int _getBigInt64(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmI64>('Function.prototype.call.bind(DataView.prototype.getBigInt64)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toInt();

@pragma("wasm:prefer-inline")
void _setBigInt64(
        WasmExternRef? ref, int byteOffset, int value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setBigInt64)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmI64.fromInt(value),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
double _getFloat32(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmF32>('Function.prototype.call.bind(DataView.prototype.getFloat32)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toDouble();

@pragma("wasm:prefer-inline")
void _setFloat32(
        WasmExternRef? ref, int byteOffset, num value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setFloat32)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmF32.fromDouble(value.toDouble()),
        WasmI32.fromBool(littleEndian));

@pragma("wasm:prefer-inline")
double _getFloat64(WasmExternRef? ref, int byteOffset, bool littleEndian) => js
    .JS<WasmF64>('Function.prototype.call.bind(DataView.prototype.getFloat64)',
        ref, WasmI32.fromInt(byteOffset), WasmI32.fromBool(littleEndian))
    .toDouble();

@pragma("wasm:prefer-inline")
void _setFloat64(
        WasmExternRef? ref, int byteOffset, num value, bool littleEndian) =>
    js.JS<void>(
        'Function.prototype.call.bind(DataView.prototype.setFloat64)',
        ref,
        WasmI32.fromInt(byteOffset),
        WasmF64.fromDouble(value.toDouble()),
        WasmI32.fromBool(littleEndian));
