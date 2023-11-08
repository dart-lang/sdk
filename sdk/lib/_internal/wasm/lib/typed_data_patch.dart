// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_simd';
import 'dart:_typed_data';
import 'dart:_wasm';

@patch
class ByteData {
  @patch
  factory ByteData(int length) => I8ByteData(length);
}

@patch
class Int8List {
  @patch
  factory Int8List(int length) => I8List(length);

  @patch
  factory Int8List.fromList(List<int> elements) =>
      I8List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint8List {
  @patch
  factory Uint8List(int length) => U8List(length);

  @patch
  factory Uint8List.fromList(List<int> elements) =>
      U8List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint8ClampedList {
  @patch
  factory Uint8ClampedList(int length) => U8ClampedList(length);

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) =>
      U8ClampedList(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int16List {
  @patch
  factory Int16List(int length) => I16List(length);

  @patch
  factory Int16List.fromList(List<int> elements) =>
      I16List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint16List {
  @patch
  factory Uint16List(int length) => U16List(length);

  @patch
  factory Uint16List.fromList(List<int> elements) =>
      U16List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int32List {
  @patch
  factory Int32List(int length) => I32List(length);

  @patch
  factory Int32List.fromList(List<int> elements) =>
      I32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint32List {
  @patch
  factory Uint32List(int length) => U32List(length);

  @patch
  factory Uint32List.fromList(List<int> elements) =>
      U32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int64List {
  @patch
  factory Int64List(int length) => I64List(length);

  @patch
  factory Int64List.fromList(List<int> elements) =>
      I64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint64List {
  @patch
  factory Uint64List(int length) => U64List(length);

  @patch
  factory Uint64List.fromList(List<int> elements) =>
      U64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float32List {
  @patch
  factory Float32List(int length) => F32List(length);

  @patch
  factory Float32List.fromList(List<double> elements) =>
      F32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float64List {
  @patch
  factory Float64List(int length) => F64List(length);

  @patch
  factory Float64List.fromList(List<double> elements) =>
      F64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class UnmodifiableUint8ListView {
  @patch
  factory UnmodifiableUint8ListView(Uint8List list) {
    if (list is U8List) {
      return UnmodifiableU8List(list);
    } else {
      return UnmodifiableSlowU8List(list);
    }
  }
}

@patch
class UnmodifiableInt8ListView {
  @patch
  factory UnmodifiableInt8ListView(Int8List list) {
    if (list is I8List) {
      return UnmodifiableI8List(list);
    } else {
      return UnmodifiableSlowI8List(list);
    }
  }
}

@patch
class UnmodifiableUint8ClampedListView {
  @patch
  factory UnmodifiableUint8ClampedListView(Uint8ClampedList list) {
    if (list is U8ClampedList) {
      return UnmodifiableU8ClampedList(list);
    } else {
      return UnmodifiableSlowU8ClampedList(list);
    }
  }
}

@patch
class UnmodifiableUint16ListView {
  @patch
  factory UnmodifiableUint16ListView(Uint16List list) {
    if (list is U16List) {
      return UnmodifiableU16List(list);
    } else {
      return UnmodifiableSlowU16List(list);
    }
  }
}

@patch
class UnmodifiableInt16ListView {
  @patch
  factory UnmodifiableInt16ListView(Int16List list) {
    if (list is I16List) {
      return UnmodifiableI16List(list);
    } else {
      return UnmodifiableSlowI16List(list);
    }
  }
}

@patch
class UnmodifiableUint32ListView {
  @patch
  factory UnmodifiableUint32ListView(Uint32List list) {
    if (list is U32List) {
      return UnmodifiableU32List(list);
    } else {
      return UnmodifiableSlowU32List(list);
    }
  }
}

@patch
class UnmodifiableInt32ListView {
  @patch
  factory UnmodifiableInt32ListView(Int32List list) {
    if (list is I32List) {
      return UnmodifiableI32List(list);
    } else {
      return UnmodifiableSlowI32List(list);
    }
  }
}

@patch
class UnmodifiableUint64ListView {
  @patch
  factory UnmodifiableUint64ListView(Uint64List list) {
    if (list is U64List) {
      return UnmodifiableU64List(list);
    } else {
      return UnmodifiableSlowU64List(list);
    }
  }
}

@patch
class UnmodifiableInt64ListView {
  @patch
  factory UnmodifiableInt64ListView(Int64List list) {
    if (list is I64List) {
      return UnmodifiableI64List(list);
    } else {
      return UnmodifiableSlowI64List(list);
    }
  }
}

@patch
class UnmodifiableFloat32ListView {
  @patch
  factory UnmodifiableFloat32ListView(Float32List list) {
    if (list is F32List) {
      return UnmodifiableF32List(list);
    } else {
      return UnmodifiableSlowF32List(list);
    }
  }
}

@patch
class UnmodifiableFloat64ListView {
  @patch
  factory UnmodifiableFloat64ListView(Float64List list) {
    if (list is F64List) {
      return UnmodifiableF64List(list);
    } else {
      return UnmodifiableSlowF64List(list);
    }
  }
}

@patch
class UnmodifiableByteBufferView implements ByteBuffer {
  @patch
  factory UnmodifiableByteBufferView(ByteBuffer data) =>
      // TODO(omersa): This will break when `data` is `JSArrayBufferImpl`.
      // Implement an interface for byte buffer that can be made unmodifiable
      // and implement it in all byte buffers, use that type here.
      UnmodifiableByteBuffer(unsafeCast<ByteBufferBase>(data));
}

@patch
class UnmodifiableByteDataView implements ByteData {
  @patch
  factory UnmodifiableByteDataView(ByteData data) =>
      // TODO(omersa): Same as above, this will break when `data` is
      // `JSDataViewImpl`. Add an interface for `ByteData` that can be made
      // immutable, implement it in all `ByteData` subtypes.
      unsafeCast<ByteDataBase>(data).immutable();
}

@patch
class Int32x4List {
  @patch
  factory Int32x4List(int length) = NaiveInt32x4List;

  @patch
  factory Int32x4List.fromList(List<Int32x4> elements) =
      NaiveInt32x4List.fromList;
}

@patch
class Float32x4List {
  @patch
  factory Float32x4List(int length) = NaiveFloat32x4List;

  @patch
  factory Float32x4List.fromList(List<Float32x4> elements) =
      NaiveFloat32x4List.fromList;
}

@patch
class Float64x2List {
  @patch
  factory Float64x2List(int length) = NaiveFloat64x2List;

  @patch
  factory Float64x2List.fromList(List<Float64x2> elements) =
      NaiveFloat64x2List.fromList;
}

@patch
abstract class UnmodifiableInt32x4ListView implements Int32x4List {
  @patch
  factory UnmodifiableInt32x4ListView(Int32x4List list) =>
      NaiveUnmodifiableInt32x4List(list);
}

@patch
abstract class UnmodifiableFloat32x4ListView implements Float32x4List {
  @patch
  factory UnmodifiableFloat32x4ListView(Float32x4List list) =>
      NaiveUnmodifiableFloat32x4List(list);
}

@patch
abstract class UnmodifiableFloat64x2ListView implements Float64x2List {
  @patch
  factory UnmodifiableFloat64x2ListView(Float64x2List list) =>
      NaiveUnmodifiableFloat64x2List(list);
}
