// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// File is compiled with checked in SDK, update [FfiNative]s to [Native] when
// SDK is rolled.
// ignore_for_file: deprecated_member_use

import 'dart:typed_data';

import 'package:compiler/src/source_file_provider.dart';
import 'package:mmap/mmap.dart';

Uint8List viewOfFile(String filename) {
  final mappedFile = mmapFile(filename);
  return mappedFile.fileBytes;
}

class MemoryMapSourceFileByteReader implements SourceFileByteReader {
  const MemoryMapSourceFileByteReader();

  @override
  Uint8List getBytes(String filename) {
    if (supportsMMap) {
      try {
        return viewOfFile(filename);
      } catch (e) {
        return readAll(filename);
      }
    } else {
      return readAll(filename);
    }
  }
}
