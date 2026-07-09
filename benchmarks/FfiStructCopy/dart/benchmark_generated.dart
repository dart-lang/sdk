// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';

import 'FfiStructCopy.dart';

final class Struct1Bytes extends Struct {
  @Array(1)
  external Array<Uint8> a0;
}

final class Struct1BytesWrapper extends Struct {
  external Struct1Bytes nested;
}

final class Copy1Bytes extends StructCopyBenchmark {
  @override
  Pointer<Struct1BytesWrapper> from = nullptr;
  @override
  Pointer<Struct1BytesWrapper> to = nullptr;

  Copy1Bytes() : super('FfiStructCopy.Copy1Bytes');

  @override
  int get copySizeInBytes => sizeOf<Struct1BytesWrapper>();

  @override
  void setup(int batchSize) {
    from = calloc(batchSize);
    to = calloc(batchSize);
  }

  @override
  void run(int batchSize) {
    for (int i = 0; i < batchSize; i++) {
      to[i].nested = from[i].nested;
    }
  }
}

final class Struct32Bytes extends Struct {
  @Array(32)
  external Array<Uint8> a0;
}

final class Struct32BytesWrapper extends Struct {
  external Struct32Bytes nested;
}

final class Copy32Bytes extends StructCopyBenchmark {
  @override
  Pointer<Struct32BytesWrapper> from = nullptr;
  @override
  Pointer<Struct32BytesWrapper> to = nullptr;

  Copy32Bytes() : super('FfiStructCopy.Copy32Bytes');

  @override
  int get copySizeInBytes => sizeOf<Struct32BytesWrapper>();

  @override
  void setup(int batchSize) {
    from = calloc(batchSize);
    to = calloc(batchSize);
  }

  @override
  void run(int batchSize) {
    for (int i = 0; i < batchSize; i++) {
      to[i].nested = from[i].nested;
    }
  }
}

final class Struct1024Bytes extends Struct {
  @Array(1024)
  external Array<Uint8> a0;
}

final class Struct1024BytesWrapper extends Struct {
  external Struct1024Bytes nested;
}

final class Copy1024Bytes extends StructCopyBenchmark {
  @override
  Pointer<Struct1024BytesWrapper> from = nullptr;
  @override
  Pointer<Struct1024BytesWrapper> to = nullptr;

  Copy1024Bytes() : super('FfiStructCopy.Copy1024Bytes');

  @override
  int get copySizeInBytes => sizeOf<Struct1024BytesWrapper>();

  @override
  void setup(int batchSize) {
    from = calloc(batchSize);
    to = calloc(batchSize);
  }

  @override
  void run(int batchSize) {
    for (int i = 0; i < batchSize; i++) {
      to[i].nested = from[i].nested;
    }
  }
}

final class Struct32768Bytes extends Struct {
  @Array(32768)
  external Array<Uint8> a0;
}

final class Struct32768BytesWrapper extends Struct {
  external Struct32768Bytes nested;
}

final class Copy32768Bytes extends StructCopyBenchmark {
  @override
  Pointer<Struct32768BytesWrapper> from = nullptr;
  @override
  Pointer<Struct32768BytesWrapper> to = nullptr;

  Copy32768Bytes() : super('FfiStructCopy.Copy32768Bytes');

  @override
  int get copySizeInBytes => sizeOf<Struct32768BytesWrapper>();

  @override
  void setup(int batchSize) {
    from = calloc(batchSize);
    to = calloc(batchSize);
  }

  @override
  void run(int batchSize) {
    for (int i = 0; i < batchSize; i++) {
      to[i].nested = from[i].nested;
    }
  }
}
