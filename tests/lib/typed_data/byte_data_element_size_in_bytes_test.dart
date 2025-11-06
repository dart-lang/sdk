// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// These tests are mainly for dart2wasm, where we have multiple `ByteData`
// classes with differently typed backing arrays.

import 'dart:typed_data';
import "package:expect/expect.dart";

const bool isJS = identical(1, 1.0);

void main() {
  Expect.equals(
    1,
    ByteData.view(Int8List.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Uint8List.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Uint8ClampedList.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Int16List.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Uint16List.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Int32List.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Uint32List.fromList([]).buffer).elementSizeInBytes,
  );

  if (!isJS) {
    Expect.equals(
      1,
      ByteData.view(Int64List.fromList([]).buffer).elementSizeInBytes,
    );

    Expect.equals(
      1,
      ByteData.view(Uint64List.fromList([]).buffer).elementSizeInBytes,
    );
  }

  Expect.equals(
    1,
    ByteData.view(Float32List.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Float64List.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Float32x4List.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Float64x2List.fromList([]).buffer).elementSizeInBytes,
  );

  Expect.equals(
    1,
    ByteData.view(Int32x4List.fromList([]).buffer).elementSizeInBytes,
  );
}
