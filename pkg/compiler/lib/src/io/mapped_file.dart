// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// File is compiled with checked in SDK, update [FfiNative]s to [Native] when
// SDK is rolled.
// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:compiler/src/source_file_provider.dart';
import 'package:mmap/mmap.dart';

Uint8List viewOfFile(String filename, bool zeroTerminated) {
  final mappedFile = mmapFile(filename);
  if (!zeroTerminated) {
    return mappedFile.fileBytes;
  }
  if (mappedFile.hasZeroPadding) {
    return mappedFile.fileBytesZeroTerminated;
  }
  // In the rare case we need a zero-terminated list and the file size
  // is exactly page-aligned we need to allocate a new list with extra
  // room for the terminating 0.
  return Uint8List(mappedFile.fileLength + 1)
    ..setRange(0, mappedFile.fileLength, mappedFile.fileBytes);
}

class MemoryMapSourceFileByteReader implements SourceFileByteReader {
  const MemoryMapSourceFileByteReader();

  @override
  Uint8List getBytes(String filename, {bool zeroTerminated = true}) {
    if (supportsMMap) {
      try {
        return viewOfFile(filename, zeroTerminated);
      } catch (e) {
        return readAll(filename, zeroTerminated: zeroTerminated);
      }
    } else {
      return readAll(filename, zeroTerminated: zeroTerminated);
    }
  }
}
