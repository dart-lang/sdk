// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_internal' show patch, unsafeCast;
import 'dart:_wasm';

@patch
class ByteData {
  @patch
  factory ByteData(int length) => _I8ByteData(length);
}

@patch
class Int8List {
  @patch
  factory Int8List(int length) => _I8List(length);

  @patch
  factory Int8List.fromList(List<int> elements) =>
      _I8List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint8List {
  @patch
  factory Uint8List(int length) => _U8List(length);

  @patch
  factory Uint8List.fromList(List<int> elements) =>
      _U8List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint8ClampedList {
  @patch
  factory Uint8ClampedList(int length) => _U8ClampedList(length);

  @patch
  factory Uint8ClampedList.fromList(List<int> elements) =>
      _U8ClampedList(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int16List {
  @patch
  factory Int16List(int length) => _I16List(length);

  @patch
  factory Int16List.fromList(List<int> elements) =>
      _I16List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint16List {
  @patch
  factory Uint16List(int length) => _U16List(length);

  @patch
  factory Uint16List.fromList(List<int> elements) =>
      _U16List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int32List {
  @patch
  factory Int32List(int length) => _I32List(length);

  @patch
  factory Int32List.fromList(List<int> elements) =>
      _I32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint32List {
  @patch
  factory Uint32List(int length) => _U32List(length);

  @patch
  factory Uint32List.fromList(List<int> elements) =>
      _U32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Int64List {
  @patch
  factory Int64List(int length) => _I64List(length);

  @patch
  factory Int64List.fromList(List<int> elements) =>
      _I64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Uint64List {
  @patch
  factory Uint64List(int length) => _U64List(length);

  @patch
  factory Uint64List.fromList(List<int> elements) =>
      _U64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float32List {
  @patch
  factory Float32List(int length) => _F32List(length);

  @patch
  factory Float32List.fromList(List<double> elements) =>
      _F32List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class Float64List {
  @patch
  factory Float64List(int length) => _F64List(length);

  @patch
  factory Float64List.fromList(List<double> elements) =>
      _F64List(elements.length)..setRange(0, elements.length, elements);
}

@patch
class UnmodifiableUint8ListView {
  @patch
  factory UnmodifiableUint8ListView(Uint8List list) {
    if (list is _U8List) {
      return _UnmodifiableU8List(list);
    } else {
      return _UnmodifiableSlowU8List(list);
    }
  }
}

@patch
class UnmodifiableInt8ListView {
  @patch
  factory UnmodifiableInt8ListView(Int8List list) {
    if (list is _I8List) {
      return _UnmodifiableI8List(list);
    } else {
      return _UnmodifiableSlowI8List(list);
    }
  }
}

@patch
class UnmodifiableUint8ClampedListView {
  @patch
  factory UnmodifiableUint8ClampedListView(Uint8ClampedList list) {
    if (list is _U8ClampedList) {
      return _UnmodifiableU8ClampedList(list);
    } else {
      return _UnmodifiableSlowU8ClampedList(list);
    }
  }
}

@patch
class UnmodifiableUint16ListView {
  @patch
  factory UnmodifiableUint16ListView(Uint16List list) {
    if (list is _U16List) {
      return _UnmodifiableU16List(list);
    } else {
      return _UnmodifiableSlowU16List(list);
    }
  }
}

@patch
class UnmodifiableInt16ListView {
  @patch
  factory UnmodifiableInt16ListView(Int16List list) {
    if (list is _I16List) {
      return _UnmodifiableI16List(list);
    } else {
      return _UnmodifiableSlowI16List(list);
    }
  }
}

@patch
class UnmodifiableUint32ListView {
  @patch
  factory UnmodifiableUint32ListView(Uint32List list) {
    if (list is _U32List) {
      return _UnmodifiableU32List(list);
    } else {
      return _UnmodifiableSlowU32List(list);
    }
  }
}

@patch
class UnmodifiableInt32ListView {
  @patch
  factory UnmodifiableInt32ListView(Int32List list) {
    if (list is _I32List) {
      return _UnmodifiableI32List(list);
    } else {
      return _UnmodifiableSlowI32List(list);
    }
  }
}

@patch
class UnmodifiableUint64ListView {
  @patch
  factory UnmodifiableUint64ListView(Uint64List list) {
    if (list is _U64List) {
      return _UnmodifiableU64List(list);
    } else {
      return _UnmodifiableSlowU64List(list);
    }
  }
}

@patch
class UnmodifiableInt64ListView {
  @patch
  factory UnmodifiableInt64ListView(Int64List list) {
    if (list is _I64List) {
      return _UnmodifiableI64List(list);
    } else {
      return _UnmodifiableSlowI64List(list);
    }
  }
}

@patch
class UnmodifiableFloat32ListView {
  @patch
  factory UnmodifiableFloat32ListView(Float32List list) {
    if (list is _F32List) {
      return _UnmodifiableF32List(list);
    } else {
      return _UnmodifiableSlowF32List(list);
    }
  }
}

@patch
class UnmodifiableFloat64ListView {
  @patch
  factory UnmodifiableFloat64ListView(Float64List list) {
    if (list is _F64List) {
      return _UnmodifiableF64List(list);
    } else {
      return _UnmodifiableSlowF64List(list);
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
      _UnmodifiableByteBuffer(unsafeCast<_ByteBufferBase>(data));
}

@patch
class UnmodifiableByteDataView implements ByteData {
  @patch
  factory UnmodifiableByteDataView(ByteData data) =>
      // TODO(omersa): Same as above, this will break when `data` is
      // `JSDataViewImpl`. Add an interface for `ByteData` that can be made
      // immutable, implement it in all `ByteData` subtypes.
      unsafeCast<_ByteDataBase>(data).immutable();
}
