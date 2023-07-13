// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._js_types;

final class JSArrayBufferImpl implements ByteBuffer {
  final WasmExternRef? _ref;

  JSArrayBufferImpl(this._ref);

  WasmExternRef? get toExternRef => _ref;

  @override
  int get lengthInBytes =>
      js.JS<double>('o => o.byteLength', toExternRef).toInt();

  Uint8List asUint8List([int offsetInBytes = 0, int? length]) =>
      JSUint8ArrayImpl.view(this, offsetInBytes, length);

  Int8List asInt8List([int offsetInBytes = 0, int? length]) =>
      JSInt8ArrayImpl.view(this, offsetInBytes, length);

  Uint8ClampedList asUint8ClampedList([int offsetInBytes = 0, int? length]) =>
      JSUint8ClampedArrayImpl.view(this, offsetInBytes, length);

  Uint16List asUint16List([int offsetInBytes = 0, int? length]) =>
      JSUint16ArrayImpl.view(this, offsetInBytes, length);

  Int16List asInt16List([int offsetInBytes = 0, int? length]) =>
      JSInt16ArrayImpl.view(this, offsetInBytes, length);

  Uint32List asUint32List([int offsetInBytes = 0, int? length]) =>
      JSUint32ArrayImpl.view(this, offsetInBytes, length);

  Int32List asInt32List([int offsetInBytes = 0, int? length]) =>
      JSInt32ArrayImpl.view(this, offsetInBytes, length);

  Uint64List asUint64List([int offsetInBytes = 0, int? length]) =>
      JSBigUint64ArrayImpl.view(this, offsetInBytes, length);

  Int64List asInt64List([int offsetInBytes = 0, int? length]) =>
      JSBigInt64ArrayImpl.view(this, offsetInBytes, length);

  Int32x4List asInt32x4List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Int32x4List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Int32x4List.bytesPerElement;
    final storage = JSInt32ArrayImpl.view(this, offsetInBytes, length * 4);
    return JSInt32x4ArrayImpl._externalStorage(storage);
  }

  Float32List asFloat32List([int offsetInBytes = 0, int? length]) =>
      JSFloat32ArrayImpl.view(this, offsetInBytes, length);

  Float64List asFloat64List([int offsetInBytes = 0, int? length]) =>
      JSFloat64ArrayImpl.view(this, offsetInBytes, length);

  Float32x4List asFloat32x4List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Float32x4List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Float32x4List.bytesPerElement;
    final storage = JSFloat32ArrayImpl.view(this, offsetInBytes, length * 4);
    return JSFloat32x4ArrayImpl._externalStorage(storage);
  }

  Float64x2List asFloat64x2List([int offsetInBytes = 0, int? length]) {
    _offsetAlignmentCheck(offsetInBytes, Float64x2List.bytesPerElement);
    length ??= (lengthInBytes - offsetInBytes) ~/ Float64x2List.bytesPerElement;
    final storage = JSFloat64ArrayImpl.view(this, offsetInBytes, length * 2);
    return JSFloat64x2ArrayImpl._externalStorage(storage);
  }

  ByteData asByteData([int offsetInBytes = 0, int? length]) =>
      JSDataViewImpl.view(this, offsetInBytes, length);

  @override
  bool operator ==(Object that) =>
      that is JSArrayBufferImpl && js.areEqualInJS(_ref, that._ref);

  @override
  int get hashCode => 0;
}

final class JSArrayBufferViewImpl implements TypedData {
  final WasmExternRef? _ref;

  JSArrayBufferViewImpl(this._ref);

  WasmExternRef? get toExternRef => _ref;

  @override
  ByteBuffer get buffer =>
      JSArrayBufferImpl(js.JS<WasmExternRef?>('o => o.buffer', toExternRef));

  @override
  int get lengthInBytes =>
      js.JS<double>('o => o.byteLength', toExternRef).toInt();

  @override
  int get offsetInBytes =>
      js.JS<double>('o => o.byteOffset', toExternRef).toInt();

  @override
  int get elementSizeInBytes =>
      js.JS<double>('o => o.BYTES_PER_ELEMENT', toExternRef).toInt();

  int get length => js.JS<double>('o => o.length', toExternRef).toInt();

  @override
  bool operator ==(Object that) =>
      that is JSArrayBufferViewImpl && js.areEqualInJS(_ref, that._ref);

  @override
  int get hashCode => 0;
}

final class JSDataViewImpl extends JSArrayBufferViewImpl implements ByteData {
  JSDataViewImpl(super._ref);

  factory JSDataViewImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    WasmExternRef? jsBuffer;
    if (length == null) {
      jsBuffer = js.JS<WasmExternRef?>('(b, o) => new DataView(b, o)',
          buffer.toExternRef, offsetInBytes.toDouble());
    } else {
      jsBuffer = js.JS<WasmExternRef?>('(b, o, l) => new DataView(b, o, l)',
          buffer.toExternRef, offsetInBytes.toDouble(), length.toDouble());
    }
    return JSDataViewImpl(jsBuffer);
  }

  @override
  int get elementSizeInBytes => 1;

  double getFloat32(int byteOffset, [Endian endian = Endian.big]) =>
      js.JS<double>('(b, o, e) => b.getFloat32(o, e)', toExternRef,
          byteOffset.toDouble(), Endian.little == endian);

  double getFloat64(int byteOffset, [Endian endian = Endian.big]) =>
      js.JS<double>('(b, o, e) => b.getFloat64(o, e)', toExternRef,
          byteOffset.toDouble(), Endian.little == endian);

  int getInt16(int byteOffset, [Endian endian = Endian.big]) => js
      .JS<double>('(b, o, e) => b.getInt16(o, e)', toExternRef,
          byteOffset.toDouble(), Endian.little == endian)
      .toInt();

  int getInt32(int byteOffset, [Endian endian = Endian.big]) => js
      .JS<double>('(b, o, e) => b.getInt32(o, e)', toExternRef,
          byteOffset.toDouble(), Endian.little == endian)
      .toInt();

  int getInt64(int byteOffset, [Endian endian = Endian.big]) => js.JS<int>(
      '(b, o, e) => b.getBigInt64(o, e)',
      toExternRef,
      byteOffset.toDouble(),
      Endian.little == endian);

  int getInt8(int byteOffset) => js
      .JS<double>('(b, o) => b.getInt8(o)', toExternRef, byteOffset.toDouble())
      .toInt();

  int getUint16(int byteOffset, [Endian endian = Endian.big]) => js
      .JS<double>('(b, o, e) => b.getUint16(o, e)', toExternRef,
          byteOffset.toDouble(), Endian.little == endian)
      .toInt();

  int getUint32(int byteOffset, [Endian endian = Endian.big]) => js
      .JS<double>('(b, o, e) => b.getUint32(o, e)', toExternRef,
          byteOffset.toDouble(), Endian.little == endian)
      .toInt();

  int getUint64(int byteOffset, [Endian endian = Endian.big]) => js.JS<int>(
      '(b, o, e) => b.getBigUint64(o, e)',
      toExternRef,
      byteOffset.toDouble(),
      Endian.little == endian);

  int getUint8(int byteOffset) => js
      .JS<double>('(b, o) => b.getUint8(o)', toExternRef, byteOffset.toDouble())
      .toInt();

  void setFloat32(int byteOffset, num value, [Endian endian = Endian.big]) =>
      js.JS<void>('(b, o, v, e) => b.setFloat32(o, v, e)', toExternRef,
          byteOffset.toDouble(), value.toDouble(), Endian.little == endian);

  void setFloat64(int byteOffset, num value, [Endian endian = Endian.big]) =>
      js.JS<void>('(b, o, v, e) => b.setFloat64(o, v, e)', toExternRef,
          byteOffset.toDouble(), value.toDouble(), Endian.little == endian);

  void setInt16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      js.JS<void>('(b, o, v, e) => b.setInt16(o, v, e)', toExternRef,
          byteOffset.toDouble(), value.toDouble(), Endian.little == endian);

  void setInt32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      js.JS<void>('(b, o, v, e) => b.setInt32(o, v, e)', toExternRef,
          byteOffset.toDouble(), value.toDouble(), Endian.little == endian);

  void setInt64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      js.JS<void>('(b, o, v, e) => b.setBigInt64(o, v, e)', toExternRef,
          byteOffset.toDouble(), value, Endian.little == endian);

  void setInt8(int byteOffset, int value) => js.JS<void>(
      '(b, o, v) => b.setInt8(o, v)',
      toExternRef,
      byteOffset.toDouble(),
      value.toDouble());

  void setUint16(int byteOffset, int value, [Endian endian = Endian.big]) =>
      js.JS<void>('(b, o, v, e) => b.setUint16(o, v, e)', toExternRef,
          byteOffset.toDouble(), value.toDouble(), Endian.little == endian);

  void setUint32(int byteOffset, int value, [Endian endian = Endian.big]) =>
      js.JS<void>('(b, o, v, e) => b.setUint32(o, v, e)', toExternRef,
          byteOffset.toDouble(), value.toDouble(), Endian.little == endian);

  void setUint64(int byteOffset, int value, [Endian endian = Endian.big]) =>
      js.JS<void>('(b, o, v, e) => b.setBigUint64(o, v, e)', toExternRef,
          byteOffset.toDouble(), value, Endian.little == endian);

  void setUint8(int byteOffset, int value) => js.JS<void>(
      '(b, o, v) => b.setUint8(o, v)',
      toExternRef,
      byteOffset.toDouble(),
      value.toDouble());
}

final class JSIntArrayImpl extends JSArrayBufferViewImpl
    with ListMixin<int>, FixedLengthListMixin<int> {
  JSIntArrayImpl(super._ref);

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return js
        .JS<double>('(o, i) => o[i]', toExternRef, index.toDouble())
        .toInt();
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    js.JS<void>('(o, i, v) => o[i] = v', toExternRef, index.toDouble(),
        value.toDouble());
  }

  @override
  void setAll(int index, Iterable<int> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<int> iterable,
      [int skipCount = 0]) {
    int count = end - start;
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) throw ArgumentError(skipCount);

    int sourceLength = iterable.length;
    if (sourceLength - skipCount < count) {
      throw IterableElementError.tooFew();
    }

    if (iterable is JSArrayBufferViewImpl) {
      _setRangeFast(this, start, end, count, iterable as JSArrayBufferViewImpl,
          sourceLength, skipCount);
    } else {
      List<int> otherList;
      int otherStart;
      if (iterable is List<int>) {
        otherList = iterable;
        otherStart = skipCount;
      } else {
        otherList = iterable.skip(skipCount).toList(growable: false);
        otherStart = 0;
      }
      if (otherStart + count > otherList.length) {
        throw IterableElementError.tooFew();
      }
      Lists.copy(otherList, otherStart, this, start, count);
    }
  }
}

final class JSUint8ArrayImpl extends JSIntArrayImpl implements Uint8List {
  JSUint8ArrayImpl(super._ref);

  factory JSUint8ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    WasmExternRef? jsBuffer;
    if (length == null) {
      jsBuffer = js.JS<WasmExternRef?>('(b, o) => new Uint8Array(b, o)',
          buffer.toExternRef, offsetInBytes.toDouble());
    } else {
      jsBuffer = js.JS<WasmExternRef?>('(b, o, l) => new Uint8Array(b, o, l)',
          buffer.toExternRef, offsetInBytes.toDouble(), length.toDouble());
    }
    return JSUint8ArrayImpl(jsBuffer);
  }

  @override
  Uint8List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSUint8ArrayImpl(source);
  }
}

final class JSInt8ArrayImpl extends JSIntArrayImpl implements Int8List {
  JSInt8ArrayImpl(super._ref);

  factory JSInt8ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    WasmExternRef? jsBuffer;
    if (length == null) {
      jsBuffer = js.JS<WasmExternRef?>('(b, o) => new Int8Array(b, o)',
          buffer.toExternRef, offsetInBytes.toDouble());
    } else {
      jsBuffer = js.JS<WasmExternRef?>('(b, o, l) => new Int8Array(b, o, l)',
          buffer.toExternRef, offsetInBytes.toDouble(), length.toDouble());
    }
    return JSInt8ArrayImpl(jsBuffer);
  }

  @override
  Int8List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSInt8ArrayImpl(source);
  }
}

final class JSUint8ClampedArrayImpl extends JSIntArrayImpl
    implements Uint8ClampedList {
  JSUint8ClampedArrayImpl(super._ref);

  factory JSUint8ClampedArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    WasmExternRef? jsBuffer;
    if (length == null) {
      jsBuffer = js.JS<WasmExternRef?>('(b, o) => new Uint8ClampedArray(b, o)',
          buffer.toExternRef, offsetInBytes.toDouble());
    } else {
      jsBuffer = js.JS<WasmExternRef?>(
          '(b, o, l) => new Uint8ClampedArray(b, o, l)',
          buffer.toExternRef,
          offsetInBytes.toDouble(),
          length.toDouble());
    }
    return JSUint8ClampedArrayImpl(jsBuffer);
  }

  @override
  Uint8ClampedList sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSUint8ClampedArrayImpl(source);
  }
}

final class JSUint16ArrayImpl extends JSIntArrayImpl implements Uint16List {
  JSUint16ArrayImpl(super._ref);

  factory JSUint16ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint16List.bytesPerElement);
    length ??= _adjustLength(buffer, offsetInBytes, Uint16List.bytesPerElement);
    WasmExternRef? jsBuffer = js.JS<WasmExternRef?>(
        '(b, o, l) => new Uint16Array(b, o, l)',
        buffer.toExternRef,
        offsetInBytes.toDouble(),
        length.toDouble());
    return JSUint16ArrayImpl(jsBuffer);
  }

  @override
  Uint16List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSUint16ArrayImpl(source);
  }
}

final class JSInt16ArrayImpl extends JSIntArrayImpl implements Int16List {
  JSInt16ArrayImpl(super._ref);

  factory JSInt16ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int16List.bytesPerElement);
    length ??= _adjustLength(buffer, offsetInBytes, Int16List.bytesPerElement);
    WasmExternRef? jsBuffer = js.JS<WasmExternRef?>(
        '(b, o, l) => new Int16Array(b, o, l)',
        buffer.toExternRef,
        offsetInBytes.toDouble(),
        length.toDouble());
    return JSInt16ArrayImpl(jsBuffer);
  }

  @override
  Int16List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSInt16ArrayImpl(source);
  }
}

final class JSUint32ArrayImpl extends JSIntArrayImpl implements Uint32List {
  JSUint32ArrayImpl(super._ref);

  factory JSUint32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint32List.bytesPerElement);
    length ??= _adjustLength(buffer, offsetInBytes, Uint32List.bytesPerElement);
    WasmExternRef? jsBuffer = js.JS<WasmExternRef?>(
        '(b, o, l) => new Uint32Array(b, o, l)',
        buffer.toExternRef,
        offsetInBytes.toDouble(),
        length.toDouble());
    return JSUint32ArrayImpl(jsBuffer);
  }

  @override
  Uint32List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSUint32ArrayImpl(source);
  }
}

final class JSInt32ArrayImpl extends JSIntArrayImpl implements Int32List {
  JSInt32ArrayImpl(super._ref);

  factory JSInt32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int32List.bytesPerElement);
    length ??= _adjustLength(buffer, offsetInBytes, Int32List.bytesPerElement);
    WasmExternRef? jsBuffer = js.JS<WasmExternRef?>(
        '(b, o, l) => new Int32Array(b, o, l)',
        buffer.toExternRef,
        offsetInBytes.toDouble(),
        length.toDouble());
    return JSInt32ArrayImpl(jsBuffer);
  }

  @override
  Int32List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSInt32ArrayImpl(source);
  }
}

final class JSInt32x4ArrayImpl
    with ListMixin<Int32x4>, FixedLengthListMixin<Int32x4>
    implements Int32x4List {
  final JSInt32ArrayImpl _storage;

  JSInt32x4ArrayImpl._externalStorage(JSInt32ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Int32x4List.bytesPerElement;

  @override
  int get length => _storage.length ~/ 4;

  @override
  Int32x4 operator [](int index) {
    IndexError.check(index, length);
    int _x = _storage[(index * 4) + 0];
    int _y = _storage[(index * 4) + 1];
    int _z = _storage[(index * 4) + 2];
    int _w = _storage[(index * 4) + 3];
    return Int32x4(_x, _y, _z, _w);
  }

  @override
  void operator []=(int index, Int32x4 value) {
    IndexError.check(index, length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  @override
  Int32x4List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSInt32x4ArrayImpl._externalStorage(
        _storage.sublist(start * 4, stop * 4) as JSInt32ArrayImpl);
  }
}

final class JSBigIntArrayImpl extends JSIntArrayImpl {
  JSBigIntArrayImpl(super._ref);

  @override
  int operator [](int index) {
    IndexError.check(index, length);
    return js.JS<int>('(o, i) => o[i]', toExternRef, index.toDouble()).toInt();
  }

  @override
  void operator []=(int index, int value) {
    IndexError.check(index, length);
    js.JS<void>('(o, i, v) => o[i] = v', toExternRef, index.toDouble(), value);
  }
}

final class JSBigUint64ArrayImpl extends JSBigIntArrayImpl
    implements Uint64List {
  JSBigUint64ArrayImpl(super._ref);

  factory JSBigUint64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Uint64List.bytesPerElement);
    length ??= _adjustLength(buffer, offsetInBytes, Uint64List.bytesPerElement);
    WasmExternRef? jsBuffer = js.JS<WasmExternRef?>(
        '(b, o, l) => new BigUint64Array(b, o, l)',
        buffer.toExternRef,
        offsetInBytes.toDouble(),
        length.toDouble());
    return JSBigUint64ArrayImpl(jsBuffer);
  }

  @override
  Uint64List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSBigUint64ArrayImpl(source);
  }
}

final class JSBigInt64ArrayImpl extends JSBigIntArrayImpl implements Int64List {
  JSBigInt64ArrayImpl(super._ref);

  factory JSBigInt64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Int64List.bytesPerElement);
    length ??= _adjustLength(buffer, offsetInBytes, Int64List.bytesPerElement);
    WasmExternRef? jsBuffer = js.JS<WasmExternRef?>(
        '(b, o, l) => new BigInt64Array(b, o, l)',
        buffer.toExternRef,
        offsetInBytes.toDouble(),
        length.toDouble());
    return JSBigInt64ArrayImpl(jsBuffer);
  }

  @override
  Int64List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSBigInt64ArrayImpl(source);
  }
}

final class JSFloatArrayImpl extends JSArrayBufferViewImpl
    with ListMixin<double>, FixedLengthListMixin<double> {
  JSFloatArrayImpl(super._ref);

  @override
  double operator [](int index) {
    IndexError.check(index, length);
    return js.JS<double>('(o, i) => o[i]', toExternRef, index.toDouble());
  }

  @override
  void operator []=(int index, double value) {
    IndexError.check(index, length);
    js.JS<void>('(o, i, v) => o[i] = v', toExternRef, index.toDouble(),
        value.toDouble());
  }

  @override
  void setAll(int index, Iterable<double> iterable) {
    final end = iterable.length + index;
    setRange(index, end, iterable);
  }

  @override
  void setRange(int start, int end, Iterable<double> iterable,
      [int skipCount = 0]) {
    int count = end - start;
    RangeError.checkValidRange(start, end, length);

    if (skipCount < 0) throw ArgumentError(skipCount);

    int sourceLength = iterable.length;
    if (sourceLength - skipCount < count) {
      throw IterableElementError.tooFew();
    }

    if (iterable is JSArrayBufferViewImpl) {
      _setRangeFast(this, start, end, count, iterable as JSArrayBufferViewImpl,
          sourceLength, skipCount);
    } else {
      List<double> otherList;
      int otherStart;
      if (iterable is List<double>) {
        otherList = iterable;
        otherStart = skipCount;
      } else {
        otherList = iterable.skip(skipCount).toList(growable: false);
        otherStart = 0;
      }
      if (otherStart + count > otherList.length) {
        throw IterableElementError.tooFew();
      }
      Lists.copy(otherList, otherStart, this, start, count);
    }
  }
}

final class JSFloat32ArrayImpl extends JSFloatArrayImpl implements Float32List {
  JSFloat32ArrayImpl(super._ref);

  factory JSFloat32ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Float32List.bytesPerElement);
    length ??=
        _adjustLength(buffer, offsetInBytes, Float32List.bytesPerElement);
    WasmExternRef? jsBuffer = js.JS<WasmExternRef?>(
        '(b, o, l) => new Float32Array(b, o, l)',
        buffer.toExternRef,
        offsetInBytes.toDouble(),
        length.toDouble());
    return JSFloat32ArrayImpl(jsBuffer);
  }

  @override
  Float32List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSFloat32ArrayImpl(source);
  }
}

final class JSFloat64ArrayImpl extends JSFloatArrayImpl implements Float64List {
  JSFloat64ArrayImpl(super._ref);

  factory JSFloat64ArrayImpl.view(
      JSArrayBufferImpl buffer, int offsetInBytes, int? length) {
    _offsetAlignmentCheck(offsetInBytes, Float64List.bytesPerElement);
    length ??=
        _adjustLength(buffer, offsetInBytes, Float64List.bytesPerElement);
    WasmExternRef? jsBuffer = js.JS<WasmExternRef?>(
        '(b, o, l) => new Float64Array(b, o, l)',
        buffer.toExternRef,
        offsetInBytes.toDouble(),
        length.toDouble());
    return JSFloat64ArrayImpl(jsBuffer);
  }

  @override
  Float64List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    final source = js.JS<WasmExternRef?>('(a, s, p) => a.subarray(s, p)',
        toExternRef, start.toDouble(), stop.toDouble());
    return JSFloat64ArrayImpl(source);
  }
}

final class JSFloat32x4ArrayImpl
    with ListMixin<Float32x4>, FixedLengthListMixin<Float32x4>
    implements Float32x4List {
  final JSFloat32ArrayImpl _storage;

  JSFloat32x4ArrayImpl._externalStorage(JSFloat32ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Float32x4List.bytesPerElement;

  @override
  int get length => _storage.length ~/ 4;

  @override
  Float32x4 operator [](int index) {
    IndexError.check(index, length);
    double _x = _storage[(index * 4) + 0];
    double _y = _storage[(index * 4) + 1];
    double _z = _storage[(index * 4) + 2];
    double _w = _storage[(index * 4) + 3];
    return Float32x4(_x, _y, _z, _w);
  }

  @override
  void operator []=(int index, Float32x4 value) {
    IndexError.check(index, length);
    _storage[(index * 4) + 0] = value.x;
    _storage[(index * 4) + 1] = value.y;
    _storage[(index * 4) + 2] = value.z;
    _storage[(index * 4) + 3] = value.w;
  }

  @override
  Float32x4List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat32x4ArrayImpl._externalStorage(
        _storage.sublist(start * 4, stop * 4) as JSFloat32ArrayImpl);
  }
}

final class JSFloat64x2ArrayImpl
    with ListMixin<Float64x2>, FixedLengthListMixin<Float64x2>
    implements Float64x2List {
  final JSFloat64ArrayImpl _storage;

  JSFloat64x2ArrayImpl._externalStorage(JSFloat64ArrayImpl storage)
      : _storage = storage;

  @override
  ByteBuffer get buffer => _storage.buffer;

  @override
  int get lengthInBytes => _storage.lengthInBytes;

  @override
  int get offsetInBytes => _storage.offsetInBytes;

  @override
  int get elementSizeInBytes => Float64x2List.bytesPerElement;

  @override
  int get length => _storage.length ~/ 2;

  @override
  Float64x2 operator [](int index) {
    IndexError.check(index, length);
    double _x = _storage[(index * 2) + 0];
    double _y = _storage[(index * 2) + 1];
    return Float64x2(_x, _y);
  }

  @override
  void operator []=(int index, Float64x2 value) {
    IndexError.check(index, length);
    _storage[(index * 2) + 0] = value.x;
    _storage[(index * 2) + 1] = value.y;
  }

  @override
  Float64x2List sublist(int start, [int? end]) {
    final stop = RangeError.checkValidRange(start, end, length);
    return JSFloat64x2ArrayImpl._externalStorage(
        _storage.sublist(start * 2, stop * 2) as JSFloat64ArrayImpl);
  }
}

void _setRangeFast(JSArrayBufferViewImpl target, int start, int end, int count,
    JSArrayBufferViewImpl source, int sourceLength, int skipCount) {
  WasmExternRef? jsSource;
  if (skipCount != 0 || sourceLength != count) {
    // Create a view of the exact subrange that is copied from the source.
    jsSource = js.JS<WasmExternRef?>(
        '(s, k, e) => s.subarray(k, e)',
        source.toExternRef,
        skipCount.toDouble(),
        (skipCount + count).toDouble());
  } else {
    jsSource = source.toExternRef;
  }
  js.JS<void>('(t, s, i) => t.set(s, i)', target.toExternRef, jsSource,
      start.toDouble());
}

int _adjustLength(ByteBuffer buffer, int offsetInBytes, int bytesPerElement) =>
    (buffer.lengthInBytes - offsetInBytes) ~/ bytesPerElement;

void _offsetAlignmentCheck(int offset, int alignment) {
  if ((offset % alignment) != 0) {
    throw new RangeError('Offset ($offset) must be a multiple of '
        'bytesPerElement ($alignment)');
  }
}
