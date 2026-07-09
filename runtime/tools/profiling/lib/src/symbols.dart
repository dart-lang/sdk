// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:profiling/src/elf_utils.dart';

/// Symbols of a TEXT section of a binary indexed by their file offset.
class Symbols {
  final Uint32List fileOffsets;
  final List<String> names;

  Symbols._(this.fileOffsets, this.names);

  /// Given the [fileOffset] find a symbol it falls into.
  ///
  /// We assume that symbol with index `i` starts at `fileOffsets[i]`
  /// and ends at `fileOffset[i+1]`.
  int? symbolIndex(int fileOffset) {
    int lo = 0;
    int hi = fileOffsets.length - 1;
    while (lo <= hi) {
      int mid = ((hi - lo + 1) >> 1) + lo;
      if (fileOffset < fileOffsets[mid]) {
        hi = mid - 1;
      } else if ((mid != hi) && (fileOffset >= fileOffsets[mid + 1])) {
        lo = mid + 1;
      } else {
        return mid;
      }
    }
    return null;
  }

  String? lookupName(int fileOffset) {
    final index = symbolIndex(fileOffset);
    return index != null ? names[index] : null;
  }

  /// Try loading symbols from the binary at [path].
  static Symbols? load(String path) {
    try {
      final loadingBias = loadingBiasOf(path);
      final symbols = textSymbolsOf(path).toList(growable: false);
      if (symbols.isEmpty) {
        return null;
      }

      // Ensure symbols are sorted to be able to use binary search.
      symbols.sort((a, b) => a.addr.compareTo(b.addr));

      // `nm` prints virtual addresses - convert these to file offsets
      // using loading bias.
      final fileOffsets = Uint32List(symbols.length);
      final names = List.generate(symbols.length, (i) => symbols[i].name);
      for (var i = 0; i < symbols.length; i++) {
        if (symbols[i].addr < loadingBias) {
          throw StateError(
              'unexpected: virtual address ${symbols[i].addr} of symbol '
              '${symbols[i].name} is less than loading bias $loadingBias');
        }
        fileOffsets[i] = symbols[i].addr - loadingBias;
      }

      return Symbols._(fileOffsets, names);
    } catch (_) {
      print('failed to load symbols from $path');
      return null;
    }
  }
}
