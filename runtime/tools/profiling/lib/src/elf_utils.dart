// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

/// Compute the difference between virtual address and the file offset of the
/// TEXT section. It can be used to convert virtual addresses into
/// file offsets.
int loadingBiasOf(String path) {
  final data = Process.runSync('llvm-readelf', ['-l', path]).stdout.split("\n");
  for (var line in data) {
    line = line.trim();
    if (line.startsWith("LOAD") && line.contains("R E")) {
      final components = line.split(RegExp(r"\s+"));
      final fileOffset = int.parse(components[1]);
      final virtAddr = int.parse(components[2]);
      return virtAddr - fileOffset;
    }
  }
  throw StateError('Unable to determine loading bias for $path');
}

/// Iterate over all symbols in TEXT section of the given binary.
Iterable<({int addr, String name})> textSymbolsOf(String path) {
  // Run `nm -C` on a binary to extract demangled (-C) symbols.
  final output = Process.runSync('/usr/bin/nm', ['-C', path]);
  final result = (output.stdout as String).split('\n');
  if (output.exitCode != 0) throw 'failed to run nm';

  // Parse `nm` output looking for `t` (TEXT) symbols. Each line
  // has the following format:
  final lineRe = RegExp(r"^(?<addr>[0-9a-f]+)\s+(?<typ>\w+)\s+(?<name>.*)$");
  // final symbols = <(int, String)>[];
  return result.map((line) {
    final m = lineRe.firstMatch(line);
    if (m != null && m.namedGroup('typ') == 't') {
      final addr = int.parse(m.namedGroup('addr')!, radix: 16);
      final name = m.namedGroup('name')!;
      return (addr: addr, name: name);
    }
    return null;
  }).nonNulls;
}
