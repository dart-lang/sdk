// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:expect/expect.dart';
import 'package:mmap/mmap.dart';
import 'package:mmap/src/mmap_impl.dart' show kPageSize;
import 'package:path/path.dart' as path;

final sizesToTest = [
  0,
  kPageSize - 1,
  kPageSize,
  2 * kPageSize - 1,
  2 * kPageSize
];

void main() {
  final tempDir = Directory.systemTemp.createTempSync('mmap_test');
  try {
    testMmapOrReadFile(tempDir);
    if (!supportsMMap) {
      testUnsupported();
    } else {
      testSupported(tempDir);
    }
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}

void testUnsupported() {
  Expect.throws(() => mmapFile(Platform.executable));
}

void testSupported(Directory tempDir) {
  for (final size in sizesToTest) {
    final testFile = path.join(tempDir.path, 'file.bin');
    File(testFile).writeAsBytesSync(initBytes(Uint8List(size)));

    final fileLength = File(testFile).lengthSync();
    Expect.equals(size, fileLength);

    if (size == 0) {
      Expect.throws(() => mmapFile(testFile));
      continue;
    }

    final mapping = mmapFile(testFile);
    Expect.equals(size, mapping.fileLength);
    Expect.equals(size, mapping.fileBytes.length);

    verifyBytes(mapping.fileBytes);
    if (mapping.hasZeroPadding) {
      verifyBytes(mapping.fileBytesZeroTerminated, 1);
      verifyBytes(mapping.mappedBytes, kPageSize - (size % kPageSize));
    } else {
      verifyBytes(mapping.mappedBytes);
      Expect.throws(() => mapping.fileBytesZeroTerminated);
    }
  }
}

void testMmapOrReadFile(Directory tempDir) {
  for (final size in sizesToTest) {
    final testFile = path.join(tempDir.path, 'file.bin');
    File(testFile).writeAsBytesSync(initBytes(Uint8List(size)));

    final fileLength = File(testFile).lengthSync();
    Expect.equals(size, fileLength);

    final bytes = mmapOrReadFileSync(testFile);
    Expect.equals(size, bytes.length);

    verifyBytes(bytes);
  }
}

Uint8List initBytes(Uint8List bytes) {
  for (int i = 0; i < bytes.length; ++i) {
    bytes[i] = i % 23;
  }
  return bytes;
}

void verifyBytes(Uint8List bytes, [int zeroBytes = 0]) {
  for (int i = 0; i < bytes.length - zeroBytes; ++i) {
    Expect.equals(i % 23, bytes[i]);
  }
  for (int i = bytes.length - zeroBytes; i < bytes.length; ++i) {
    Expect.equals(0, bytes[i]);
  }
}
