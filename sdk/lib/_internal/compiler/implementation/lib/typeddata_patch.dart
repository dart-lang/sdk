// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is an empty dummy patch file for the VM dart:typeddata library.
// This is needed in order to be able to generate documentation for the
// typeddata library.

patch class Int8List {
  patch factory Int8List(int length) {
    throw new UnsupportedError('Int8List');
  }

  patch factory Int8List.fromList(List<int> elements) {
    throw new UnsupportedError('Int8List.fromList');
  }

  patch factory Int8List.view(ByteBuffer buffer,
                              [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Int8List.view');
  }
}


patch class Uint8List {
  patch factory Uint8List(int length) {
    throw new UnsupportedError('Uint8List');
  }

  patch factory Uint8List.fromList(List<int> elements) {
    throw new UnsupportedError('Uint8List.fromList');
  }

  patch factory Uint8List.view(ByteBuffer buffer,
                               [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Uint8List.view');
  }
}


patch class Uint8ClampedList {
  patch factory Uint8ClampedList(int length) {
    throw new UnsupportedError('Uint8ClampedList');
  }

  patch factory Uint8ClampedList.fromList(List<int> elements) {
    throw new UnsupportedError('Uint8ClampedList.fromList');
  }

  patch factory Uint8ClampedList.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Uint8ClampedList.view');
  }
}


patch class Int16List {
  patch factory Int16List(int length) {
    throw new UnsupportedError('Int16List');

  }

  patch factory Int16List.fromList(List<int> elements) {
    throw new UnsupportedError('Int16List.fromList');
  }

  patch factory Int16List.view(ByteBuffer buffer,
                               [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Int16List.view');
  }
}


patch class Uint16List {
  patch factory Uint16List(int length) {
    throw new UnsupportedError('Uint16List');
  }

  patch factory Uint16List.fromList(List<int> elements) {
    throw new UnsupportedError('Uint16List.fromList');
  }

  patch factory Uint16List.view(ByteBuffer buffer,
                                [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Uint16List.view');
  }
}


patch class Int32List {
  patch factory Int32List(int length) {
    throw new UnsupportedError('Int32List');
  }

  patch factory Int32List.fromList(List<int> elements) {
    throw new UnsupportedError('Int32List.fromList');
  }

  patch factory Int32List.view(ByteBuffer buffer,
                               [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Int32List.view');
  }
}


patch class Uint32List {
  patch factory Uint32List(int length) {
    throw new UnsupportedError('Uint32List');
  }

  patch factory Uint32List.fromList(List<int> elements) {
    throw new UnsupportedError('Uint32List.fromList');
  }

  patch factory Uint32List.view(ByteBuffer buffer,
                                [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Uint32List.view');
  }
}


patch class Int64List {
  patch factory Int64List(int length) {
    throw new UnsupportedError('Int64List');
  }

  patch factory Int64List.fromList(List<int> elements) {
    throw new UnsupportedError('Int64List.fromList');
  }

  patch factory Int64List.view(ByteBuffer buffer,
                               [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Int64List.view');
  }
}


patch class Uint64List {
  patch factory Uint64List(int length) {
    throw new UnsupportedError('Uint64List');
  }

  patch factory Uint64List.fromList(List<int> elements) {
    throw new UnsupportedError('Uint64List.fromList');
  }

  patch factory Uint64List.view(ByteBuffer buffer,
                                [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Uint64List.view');
  }
}


patch class Float32List {
  patch factory Float32List(int length) {
    throw new UnsupportedError('Float32List');
  }

  patch factory Float32List.fromList(List<double> elements) {
    throw new UnsupportedError('Float32List.fromList');
  }

  patch factory Float32List.view(ByteBuffer buffer,
                                 [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Float32List.view');
  }
}


patch class Float64List {
  patch factory Float64List(int length) {
    throw new UnsupportedError('Float64List');
  }

  patch factory Float64List.fromList(List<double> elements) {
    throw new UnsupportedError('Float64List.fromList');
  }

  patch factory Float64List.view(ByteBuffer buffer,
                                 [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Float64List.view');
  }
}


patch class Float32x4List {
  patch factory Float32x4List(int length) {
    throw new UnsupportedError('Float32x4List');
  }

  patch factory Float32x4List.view(ByteBuffer buffer,
                                      [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('Float32x4List.view');
  }
}


patch class Float32x4 {
  patch factory Float32x4(double x, double y, double z, double w) {
    throw new UnsupportedError('Float32x4');
  }
  patch factory Float32x4.zero() {
    throw new UnsupportedError('Float32x4.zero');
  }
}


patch class Uint32x4 {
  patch factory Uint32x4(int x, int y, int z, int w) {
    throw new UnsupportedError('Uint32x4');
  }
  patch factory Uint32x4.bool(bool x, bool y, bool z, bool w) {
    throw new UnsupportedError('Uint32x4.bool');
  }
}


patch class ByteData {
  patch factory ByteData(int length) {
    throw new UnsupportedError('ByteData');
  }

  patch factory ByteData.view(ByteBuffer buffer,
                              [int offsetInBytes = 0, int length]) {
    throw new UnsupportedError('ByteData.view');
  }
}
