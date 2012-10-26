// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is an empty dummy patch file for the VM dart:scalarlist library.
// This is needed in order to be able to generate documentation for the
// scalarlist library.

patch class Int8List {
  patch factory Int8List(int length) {
    throw new UnsupportedError('Int8List');
  }

  patch factory Int8List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedError('Int8List.view');
  }
}


patch class Uint8List {
  patch factory Uint8List(int length) {
    throw new UnsupportedError('Uint8List');
  }

  patch factory Uint8List.view(ByteArray array,
                               [int start = 0, int length]) {
    throw new UnsupportedError('Uint8List.view');
  }
}


patch class Int16List {
  patch factory Int16List(int length) {
    throw new UnsupportedError('Int16List');

  }

  patch factory Int16List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedError('Int16List.view');
  }
}


patch class Uint16List {
  patch factory Uint16List(int length) {
    throw new UnsupportedError('Uint16List');
  }

  patch factory Uint16List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedError('Uint16List.view');
  }
}


patch class Int32List {
  patch factory Int32List(int length) {
    throw new UnsupportedError('Int32List');
  }

  patch factory Int32List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedError('Int32List.view');
  }
}


patch class Uint32List {
  patch factory Uint32List(int length) {
    throw new UnsupportedError('Uint32List');
  }

  patch factory Uint32List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedError('Uint32List.view');
  }
}


patch class Int64List {
  patch factory Int64List(int length) {
    throw new UnsupportedError('Int64List');
  }

  patch factory Int64List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedError('Int64List.view');
  }
}


patch class Uint64List {
  patch factory Uint64List(int length) {
    throw new UnsupportedError('Uint64List');
  }

  patch factory Uint64List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedError('Uint64List.view');
  }
}


patch class Float32List {
  patch factory Float32List(int length) {
    throw new UnsupportedError('Float32List');
  }

  patch factory Float32List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedError('Float32List.view');
  }
}


patch class Float64List {
  patch factory Float64List(int length) {
    throw new UnsupportedError('Float64List');
  }

  patch factory Float64List.view(ByteArray array, [int start = 0, int length]) {
    throw new UnsupportedError('Float64List.view');
  }
}
