// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'dart:typed_data';

// Test that the sublist of a typed_data list is of the same type.

class TypedDataConstructor {
  final String name;
  final Function create;
  final Function view;
  TypedDataConstructor(this.name, this.create, this.view);
}

List constructors = [
  new TypedDataConstructor("ByteData",
      (int n) => new ByteData(n),
      (ByteBuffer b) => new ByteData.view(b)),
  new TypedDataConstructor("Int8",
      (int n) => new Int8List(n),
      (ByteBuffer b) => new Int8List.view(b)),
  new TypedDataConstructor("Uint8",
      (int n) => new Uint8List(n),
      (ByteBuffer b) => new Uint8List.view(b)),
  new TypedDataConstructor("Uint8Clamped",
      (int n) => new Uint8ClampedList(n),
      (ByteBuffer b) => new Uint8ClampedList.view(b)),
  new TypedDataConstructor("Int16",
      (int n) => new Int16List(n),
      (ByteBuffer b) => new Int16List.view(b)),
  new TypedDataConstructor("Uint16",
      (int n) => new Uint16List(n),
      (ByteBuffer b) => new Uint16List.view(b)),
  new TypedDataConstructor("Int32",
      (int n) => new Int32List(n),
      (ByteBuffer b) => new Int32List.view(b)),
  new TypedDataConstructor("Uint32",
      (int n) => new Uint32List(n),
      (ByteBuffer b) => new Uint32List.view(b)),
  // Int64 and Uint64 are not supported on dart2js compiled code.
  new TypedDataConstructor("Int64",                /// 01: ok
      (int n) => new Int64List(n),                 /// 01: continued
      (ByteBuffer b) => new Int64List.view(b)),    /// 01: continued
  new TypedDataConstructor("Uint64",               /// 01: continued
      (int n) => new Uint64List(n),                /// 01: continued
      (ByteBuffer b) => new Uint64List.view(b)),   /// 01: continued
  new TypedDataConstructor("Float32",
      (int n) => new Float32List(n),
      (ByteBuffer b) => new Float32List.view(b)),
  new TypedDataConstructor("Float64",
      (int n) => new Float64List(n),
      (ByteBuffer b) => new Float64List.view(b)),
  new TypedDataConstructor("Int32x4",
      (int n) => new Int32x4List(n),
      (ByteBuffer b) => new Int32x4List.view(b)),
  new TypedDataConstructor("Float32x4",
      (int n) => new Float32x4List(n),
      (ByteBuffer b) => new Float32x4List.view(b))
];


void main() {
  for (var c in constructors) {
    String name = c.name;
    var typedData = c.create(64);
    Expect.isTrue(typedData is! ByteBuffer);
    ByteBuffer buffer = typedData.buffer;
    Expect.isTrue(buffer is! List && buffer is! ByteData);
    Expect.equals(buffer, typedData.buffer, name);
    for (var v in constructors) {
      String testDesc = "${v.name} view, $name buffer";
      var view = v.view(typedData.buffer);

      Expect.equals(buffer, view.buffer, testDesc);
      Expect.isTrue(view is List || view is ByteData, testDesc);
      Expect.isTrue(view.buffer is ByteBuffer, testDesc);
      Expect.isTrue(view is! ByteBuffer, testDesc);
      Expect.isTrue(view.buffer is! List && view.buffer is! ByteData, testDesc);
    }
  }
}
