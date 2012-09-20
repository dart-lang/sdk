// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is an empty dummy patch file for the VM dart:scalarlist library.
// This is needed in order to be able to generate documentation for the
// scalarlist library.

patch class Int8List {
  patch factory Int8List(int length) {
    throw new UnsupportedOperationException('Int8List');
  }

  patch factory Int8List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedOperationException('Int8List.view');
  }
}


patch class Uint8List {
  patch factory Uint8List(int length) {
    throw new UnsupportedOperationException('Uint8List');
  }

  patch factory Uint8List.view(ByteArray array,
                               [int start = 0, int length]) {
    throw new UnsupportedOperationException('Uint8List.view');
  }
}


patch class Int16List {
  patch factory Int16List(int length) {
    throw new UnsupportedOperationException('Int16List');

  }

  patch factory Int16List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedOperationException('Int16List.view');
  }
}


patch class Uint16List {
  patch factory Uint16List(int length) {
    throw new UnsupportedOperationException('Uint16List');
  }

  patch factory Uint16List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedOperationException('Uint16List.view');
  }
}


patch class Int32List {
  patch factory Int32List(int length) {
    throw new UnsupportedOperationException('Int32List');
  }

  patch factory Int32List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedOperationException('Int32List.view');
  }
}


patch class Uint32List {
  patch factory Uint32List(int length) {
    throw new UnsupportedOperationException('Uint32List');
  }

  patch factory Uint32List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedOperationException('Uint32List.view');
  }
}


patch class Int64List {
  patch factory Int64List(int length) {
    throw new UnsupportedOperationException('Int64List');
  }

  patch factory Int64List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedOperationException('Int64List.view');
  }
}


patch class Uint64List {
  patch factory Uint64List(int length) {
    throw new UnsupportedOperationException('Uint64List');
  }

  patch factory Uint64List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedOperationException('Uint64List.view');
  }
}


patch class Float32List {
  patch factory Float32List(int length) {
    throw new UnsupportedOperationException('Float32List');
  }

  patch factory Float32List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedOperationException('Float32List.view');
  }
}


patch class Float64List {
  patch factory Float64List(int length) {
    throw new UnsupportedOperationException('Float64List');
  }

  patch factory Float64List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedOperationException('Float64List.view');
  }
}
