// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show FixedLengthListMixin, patch, UnmodifiableListBase;
import 'dart:_js_helper' as js;
import 'dart:_js_types';
import 'dart:_simd';
import 'dart:_string_helper';
import 'dart:_typed_data_helper';
import 'dart:_wasm';
import 'dart:typed_data';
import 'dart:js_interop';

// TODO(joshualitt): Optimizations for this file:
//   * Move list to JS and allocate on the JS side for `fromLength`
//     constructors.

@patch
class ByteData {
  @patch
  factory ByteData(int length) {
    return JSDataViewImpl(js.JS<WasmExternRef?>(
        'l => new DataView(new ArrayBuffer(l))', length.toDouble()));
  }
}

@patch
class Uint8List {
  @patch
  factory Uint8List(int length) {
    return JSUint8ArrayImpl(
        js.JS<WasmExternRef?>('l => new Uint8Array(l)', length.toDouble()));
  }

  @patch
  factory Uint8List.fromList(List<int> elements) =>
      Uint8List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int8List {
  @patch
  factory Int8List(int length) {
    return JSInt8ArrayImpl(
        js.JS<WasmExternRef?>('l => new Int8Array(l)', length.toDouble()));
  }

  @patch
  factory Int8List.fromList(List<int> elements) =>
      Int8List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint8ClampedList {
  @patch
  factory Uint8ClampedList(int length) {
    return JSUint8ClampedArrayImpl(js.JS<WasmExternRef?>(
        'l => new Uint8ClampedArray(l)', length.toDouble()));
  }

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) =>
      Uint8ClampedList(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint16List {
  @patch
  factory Uint16List(int length) {
    return JSUint16ArrayImpl(
        js.JS<WasmExternRef?>('l => new Uint16Array(l)', length.toDouble()));
  }

  @patch
  factory Uint16List.fromList(List<int> elements) =>
      Uint16List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int16List {
  @patch
  factory Int16List(int length) {
    return JSInt16ArrayImpl(
        js.JS<WasmExternRef?>('l => new Int16Array(l)', length.toDouble()));
  }

  @patch
  factory Int16List.fromList(List<int> elements) =>
      Int16List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint32List {
  @patch
  factory Uint32List(int length) {
    return JSUint32ArrayImpl(
        js.JS<WasmExternRef?>('l => new Uint32Array(l)', length.toDouble()));
  }

  @patch
  factory Uint32List.fromList(List<int> elements) =>
      Uint32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int32List {
  @patch
  factory Int32List(int length) {
    return JSInt32ArrayImpl(
        js.JS<WasmExternRef?>('l => new Int32Array(l)', length.toDouble()));
  }

  @patch
  factory Int32List.fromList(List<int> elements) =>
      Int32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int32x4List {
  @patch
  factory Int32x4List(int length) {
    return JSInt32x4ArrayImpl.externalStorage(JSInt32ArrayImpl(js
        .JS<WasmExternRef?>('l => new Int32Array(l * 4)', length.toDouble())));
  }

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) {
    final length = elements.length;
    final l = Int32x4List(length);
    for (var i = 0; i < length; i++) {
      l[i] = elements[i];
    }
    return l;
  }
}

@patch
class Int64List {
  @patch
  factory Int64List(int length) {
    return JSBigInt64ArrayImpl(
        js.JS<WasmExternRef?>('l => new BigInt64Array(l)', length.toDouble()));
  }

  @patch
  factory Int64List.fromList(List<int> elements) =>
      Int64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint64List {
  @patch
  factory Uint64List(int length) {
    return JSBigUint64ArrayImpl(
        js.JS<WasmExternRef?>('l => new BigUint64Array(l)', length.toDouble()));
  }

  @patch
  factory Uint64List.fromList(List<int> elements) =>
      Uint64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float32List {
  @patch
  factory Float32List(int length) {
    return JSFloat32ArrayImpl(
        js.JS<WasmExternRef?>('l => new Float32Array(l)', length.toDouble()));
  }

  @patch
  factory Float32List.fromList(List<double> elements) =>
      Float32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float32x4List {
  @patch
  factory Float32x4List(int length) {
    return JSFloat32x4ArrayImpl.externalStorage(JSFloat32ArrayImpl(
        js.JS<WasmExternRef?>(
            'l => new Float32Array(l * 4)', length.toDouble())));
  }

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) {
    final length = elements.length;
    final l = Float32x4List(length);
    for (var i = 0; i < length; i++) {
      l[i] = elements[i];
    }
    return l;
  }
}

@patch
class Float64List {
  @patch
  factory Float64List(int length) {
    return JSFloat64ArrayImpl(
        js.JS<WasmExternRef?>('l => new Float64Array(l)', length.toDouble()));
  }

  @patch
  factory Float64List.fromList(List<double> elements) =>
      Float64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float64x2List {
  @patch
  factory Float64x2List(int length) {
    return JSFloat64x2ArrayImpl.externalStorage(JSFloat64ArrayImpl(
        js.JS<WasmExternRef?>(
            'l => new Float64Array(l * 2)', length.toDouble())));
  }

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) {
    final length = elements.length;
    final l = Float64x2List(length);
    for (var i = 0; i < length; i++) {
      l[i] = elements[i];
    }
    return l;
  }
}

@patch
abstract class UnmodifiableByteBufferView implements Uint8List {
  @patch
  factory UnmodifiableByteBufferView(ByteBuffer data) =
      UnmodifiableByteBufferViewImpl;
}

@patch
abstract class UnmodifiableByteDataView implements Uint8List {
  @patch
  factory UnmodifiableByteDataView(ByteData data) =
      UnmodifiableByteDataViewImpl;
}

@patch
abstract class UnmodifiableUint8ListView implements Uint8List {
  @patch
  factory UnmodifiableUint8ListView(Uint8List list) =
      UnmodifiableUint8ListViewImpl;
}

@patch
abstract class UnmodifiableInt8ListView implements Int8List {
  @patch
  factory UnmodifiableInt8ListView(Int8List list) =
      UnmodifiableInt8ListViewImpl;
}

@patch
abstract class UnmodifiableUint8ClampedListView implements Uint8ClampedList {
  @patch
  factory UnmodifiableUint8ClampedListView(Uint8ClampedList list) =
      UnmodifiableUint8ClampedListViewImpl;
}

@patch
abstract class UnmodifiableUint16ListView implements Uint16List {
  @patch
  factory UnmodifiableUint16ListView(Uint16List list) =
      UnmodifiableUint16ListViewImpl;
}

@patch
abstract class UnmodifiableInt16ListView implements Int16List {
  @patch
  factory UnmodifiableInt16ListView(Int16List list) =
      UnmodifiableInt16ListViewImpl;
}

@patch
abstract class UnmodifiableUint32ListView implements Uint32List {
  @patch
  factory UnmodifiableUint32ListView(Uint32List list) =
      UnmodifiableUint32ListViewImpl;
}

@patch
abstract class UnmodifiableInt32ListView implements Int32List {
  @patch
  factory UnmodifiableInt32ListView(Int32List list) =
      UnmodifiableInt32ListViewImpl;
}

@patch
abstract class UnmodifiableUint64ListView implements Uint64List {
  @patch
  factory UnmodifiableUint64ListView(Uint64List list) =
      UnmodifiableUint64ListViewImpl;
}

@patch
abstract class UnmodifiableInt64ListView implements Int64List {
  @patch
  factory UnmodifiableInt64ListView(Int64List list) =
      UnmodifiableInt64ListViewImpl;
}

@patch
abstract class UnmodifiableInt32x4ListView implements Int32x4List {
  @patch
  factory UnmodifiableInt32x4ListView(Int32x4List list) =
      UnmodifiableInt32x4ListViewImpl;
}

@patch
abstract class UnmodifiableFloat32x4ListView implements Float32x4List {
  @patch
  factory UnmodifiableFloat32x4ListView(Float32x4List list) =
      UnmodifiableFloat32x4ListViewImpl;
}

@patch
abstract class UnmodifiableFloat64x2ListView implements Float64x2List {
  @patch
  factory UnmodifiableFloat64x2ListView(Float64x2List list) =
      UnmodifiableFloat64x2ListViewImpl;
}

@patch
abstract class UnmodifiableFloat32ListView implements Float32List {
  @patch
  factory UnmodifiableFloat32ListView(Float32List list) =
      UnmodifiableFloat32ListViewImpl;
}

@patch
abstract class UnmodifiableFloat64ListView implements Float64List {
  @patch
  factory UnmodifiableFloat64ListView(Float64List list) =
      UnmodifiableFloat64ListViewImpl;
}
