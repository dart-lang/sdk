// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'src/mmap_impl.dart';

/// Whether memory mapping files is supported.
///
/// Currently we only support Linux.
final bool supportsMMap = finalizerCode[Abi.current()] != null;

class MemoryMappedFile {
  /// The memory mapped region of the address space as bytes.
  ///
  /// The [Uint8List]'s length is a multiple of page size and as such may be
  /// larger than the file length. The extra bytes are guaranteed to be zero.
  ///
  /// Once this list becomes unreachable the underlying mapping will be freed &
  /// file descriptor will be closed.
  final Uint8List mappedBytes;

  /// The length of the file that was mapped.
  final int fileLength;

  MemoryMappedFile(this.mappedBytes, this.fileLength);

  /// Whether the [mappedBytes] contain extra zeros after the file content.
  bool get hasZeroPadding => (fileLength % kPageSize) != 0;

  /// The bytes representing the file.
  Uint8List get fileBytes => Uint8List.sublistView(mappedBytes, 0, fileLength);

  /// The bytes representing the file plus an extra zero byte.
  Uint8List get fileBytesZeroTerminated {
    if (!hasZeroPadding) throw 'The mapped file is page aligned.';
    return Uint8List.sublistView(mappedBytes, 0, fileLength + 1);
  }
}

/// Maps the given [filename] into the virtual address space.
///
/// Notice this only works on platforms where [supportsMMap] returns `true`.
/// Notice that files of length 0 cannot be mapped.
MemoryMappedFile mmapFile(String filename) {
  if (!supportsMMap) throw 'MMap not supported';

  final Pointer<Utf8> cfilename = filename.toNativeUtf8();
  final int fd = open(cfilename, 0);
  malloc.free(cfilename);
  if (fd == 0) throw 'failed to open';
  try {
    final int length = File(filename).lengthSync();
    final int lengthRoundedUp = (length + kPageSize - 1) & ~(kPageSize - 1);
    final Pointer<Uint8> result =
        mmap(nullptr, lengthRoundedUp, kProtRead, kMapPrivate, fd, 0);
    if (result.address == kMapFailed) throw 'failed to map';
    try {
      final Uint8List bytes = toExternalDataWithFinalizer(
          result, lengthRoundedUp, lengthRoundedUp, fd);
      return MemoryMappedFile(bytes, length);
    } catch (_) {
      munmap(result, lengthRoundedUp);
      rethrow;
    }
  } catch (e) {
    close(fd);
    rethrow;
  }
}

Uint8List mmapOrReadFileSync(String filename) {
  if (supportsMMap) {
    try {
      return mmapFile(filename).fileBytes;
    } catch (_) {}
  }
  return File(filename).readAsBytesSync();
}
