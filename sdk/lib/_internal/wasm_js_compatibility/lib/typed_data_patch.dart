// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_js_types';
import 'dart:typed_data';

@patch
class ByteData {
  @patch
  factory ByteData(int length) = JSDataViewImpl;
}

@patch
class Uint8List {
  @patch
  factory Uint8List(int length) = JSUint8ArrayImpl;

  @patch
  factory Uint8List.fromList(List<int> elements) =>
      JSUint8ArrayImpl(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int8List {
  @patch
  factory Int8List(int length) = JSInt8ArrayImpl;

  @patch
  factory Int8List.fromList(List<int> elements) =>
      JSInt8ArrayImpl(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint8ClampedList {
  @patch
  factory Uint8ClampedList(int length) = JSUint8ClampedArrayImpl;

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) =>
      JSUint8ClampedArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Uint16List {
  @patch
  factory Uint16List(int length) = JSUint16ArrayImpl;

  @patch
  factory Uint16List.fromList(List<int> elements) =>
      JSUint16ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Int16List {
  @patch
  factory Int16List(int length) = JSInt16ArrayImpl;

  @patch
  factory Int16List.fromList(List<int> elements) =>
      JSInt16ArrayImpl(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint32List {
  @patch
  factory Uint32List(int length) = JSUint32ArrayImpl;

  @patch
  factory Uint32List.fromList(List<int> elements) =>
      JSUint32ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Int32List {
  @patch
  factory Int32List(int length) = JSInt32ArrayImpl;

  @patch
  factory Int32List.fromList(List<int> elements) =>
      JSInt32ArrayImpl(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int32x4List {
  @patch
  factory Int32x4List(int length) =>
      JSInt32x4ArrayImpl.externalStorage(JSInt32ArrayImpl(length * 4));

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) =>
      Int32x4List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int64List {
  @patch
  factory Int64List(int length) = JSBigInt64ArrayImpl;

  @patch
  factory Int64List.fromList(List<int> elements) =>
      JSBigInt64ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Uint64List {
  @patch
  factory Uint64List(int length) = JSBigUint64ArrayImpl;

  @patch
  factory Uint64List.fromList(List<int> elements) =>
      JSBigUint64ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Float32List {
  @patch
  factory Float32List(int length) = JSFloat32ArrayImpl;

  @patch
  factory Float32List.fromList(List<double> elements) =>
      JSFloat32ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Float32x4List {
  @patch
  factory Float32x4List(int length) =>
      JSFloat32x4ArrayImpl.externalStorage(JSFloat32ArrayImpl(length * 4));

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) =>
      Float32x4List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float64List {
  @patch
  factory Float64List(int length) = JSFloat64ArrayImpl;

  @patch
  factory Float64List.fromList(List<double> elements) =>
      JSFloat64ArrayImpl(elements.length)
        ..setRange(0, elements.length, elements);
}

@patch
class Float64x2List {
  @patch
  factory Float64x2List(int length) =>
      JSFloat64x2ArrayImpl.externalStorage(JSFloat64ArrayImpl(length * 2));

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) =>
      Float64x2List(elements.length)..setRange(0, elements.length, elements);
}

@patch
abstract class UnmodifiableByteBufferView implements Uint8List {
  @patch
  factory UnmodifiableByteBufferView(ByteBuffer data) =
      _UnmodifiableByteBufferViewImpl;
}

@patch
abstract class UnmodifiableByteDataView implements Uint8List {
  @patch
  factory UnmodifiableByteDataView(ByteData data) =
      _UnmodifiableByteDataViewImpl;
}

@patch
abstract class UnmodifiableUint8ListView implements Uint8List {
  @patch
  factory UnmodifiableUint8ListView(Uint8List list) =>
      unsafeCast<JSUint8ArrayImpl>(list).asUnmodifiableView();
}

@patch
abstract class UnmodifiableInt8ListView implements Int8List {
  @patch
  factory UnmodifiableInt8ListView(Int8List list) =>
      unsafeCast<JSInt8ArrayImpl>(list).asUnmodifiableView();
}

@patch
abstract class UnmodifiableUint8ClampedListView implements Uint8ClampedList {
  @patch
  factory UnmodifiableUint8ClampedListView(Uint8ClampedList list) =>
      unsafeCast<JSUint8ClampedArrayImpl>(list).asUnmodifiableView();
}

@patch
abstract class UnmodifiableUint16ListView implements Uint16List {
  @patch
  factory UnmodifiableUint16ListView(Uint16List list) =>
      unsafeCast<JSUint16ArrayImpl>(list).asUnmodifiableView();
}

@patch
abstract class UnmodifiableInt16ListView implements Int16List {
  @patch
  factory UnmodifiableInt16ListView(Int16List list) =>
      unsafeCast<JSInt16ArrayImpl>(list).asUnmodifiableView();
}

@patch
abstract class UnmodifiableUint32ListView implements Uint32List {
  @patch
  factory UnmodifiableUint32ListView(Uint32List list) =>
      unsafeCast<JSUint32ArrayImpl>(list).asUnmodifiableView();
}

@patch
abstract class UnmodifiableInt32ListView implements Int32List {
  @patch
  factory UnmodifiableInt32ListView(Int32List list) =>
      unsafeCast<JSInt32ArrayImpl>(list).asUnmodifiableView();
}

@patch
abstract class UnmodifiableUint64ListView implements Uint64List {
  @patch
  factory UnmodifiableUint64ListView(Uint64List list) =>
      unsafeCast<JSBigUint64ArrayImpl>(list).asUnmodifiableView();
}

@patch
abstract class UnmodifiableInt64ListView implements Int64List {
  @patch
  factory UnmodifiableInt64ListView(Int64List list) =>
      unsafeCast<JSBigInt64ArrayImpl>(list).asUnmodifiableView();
}

@patch
abstract class UnmodifiableInt32x4ListView implements Int32x4List {
  @patch
  factory UnmodifiableInt32x4ListView(Int32x4List list) =
      _UnmodifiableInt32x4ListViewImpl;
}

@patch
abstract class UnmodifiableFloat32x4ListView implements Float32x4List {
  @patch
  factory UnmodifiableFloat32x4ListView(Float32x4List list) =
      _UnmodifiableFloat32x4ListViewImpl;
}

@patch
abstract class UnmodifiableFloat64x2ListView implements Float64x2List {
  @patch
  factory UnmodifiableFloat64x2ListView(Float64x2List list) =
      _UnmodifiableFloat64x2ListViewImpl;
}

@patch
abstract class UnmodifiableFloat32ListView implements Float32List {
  @patch
  factory UnmodifiableFloat32ListView(Float32List list) =
      _UnmodifiableFloat32ListViewImpl;
}

@patch
abstract class UnmodifiableFloat64ListView implements Float64List {
  @patch
  factory UnmodifiableFloat64ListView(Float64List list) =
      _UnmodifiableFloat64ListViewImpl;
}
