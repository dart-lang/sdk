// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:expect/expect.dart';

import 'use_flag_test_helper.dart';

// Returns the signature (GUID and age) of the PDB of the PE image in
// [filename], which is stored in the CodeView record of its debug directory,
// or null if it has none. It is formatted like in the paths of symbol servers,
// where the first three fields of the GUID and the age are integers.
String? pdbSignature(String filename) {
  final data = ByteData.sublistView(File(filename).readAsBytesSync());
  int u16(int offset) => data.getUint16(offset, Endian.little);
  int u32(int offset) => data.getUint32(offset, Endian.little);

  final coffHeader = u32(0x3c) + 4;
  final optionalHeader = coffHeader + 20;
  final sectionHeaders = optionalHeader + u16(coffHeader + 16);
  final directories =
      optionalHeader + (u16(optionalHeader) == 0x20b ? 112 : 96);
  const debugDirectoryIndex = 6;
  if (u32(directories - 4) <= debugDirectoryIndex) return null;
  final debugDirectory = directories + 8 * debugDirectoryIndex;
  final debugDirectoryAddress = u32(debugDirectory);
  final debugDirectorySize = u32(debugDirectory + 4);

  // Find the file offset of the debug directory from the section headers.
  int? debugDirectoryOffset;
  for (var i = 0; i < u16(coffHeader + 2); i++) {
    final header = sectionHeaders + 40 * i;
    final address = u32(header + 12);
    if (address <= debugDirectoryAddress &&
        debugDirectoryAddress < address + u32(header + 8)) {
      debugDirectoryOffset = debugDirectoryAddress - address + u32(header + 20);
    }
  }
  if (debugDirectoryOffset == null) return null;

  const debugTypeCodeView = 2;
  const entrySize = 28;
  for (var i = 0; i < debugDirectorySize ~/ entrySize; i++) {
    final entry = debugDirectoryOffset + entrySize * i;
    if (u32(entry + 12) != debugTypeCodeView) continue;
    final record = u32(entry + 24);
    if (String.fromCharCodes(Uint8List.sublistView(data, record, record + 4)) !=
        'RSDS') {
      continue;
    }
    String hex(int value, int digits) =>
        value.toRadixString(16).padLeft(digits, '0');
    final guid = record + 4;
    return [
      hex(u32(guid), 8),
      hex(u16(guid + 4), 4),
      hex(u16(guid + 6), 4),
      for (var i = 8; i < 16; i++) hex(data.getUint8(guid + i), 2),
      u32(guid + 16).toRadixString(16),
    ].join();
  }
  return null;
}

void main() {
  final buildId = NativeRuntime.buildId;

  if (Platform.script.toString().endsWith(".dll")) {
    // The build ID of a DLL compiled from a PE/COFF snapshot is the signature
    // of its PDB. DLLs assembled from assembly snapshots are linked without
    // debugging information, and have no build ID.
    Expect.equals(pdbSignature(Platform.script.toFilePath()), buildId);
  } else if (isAOTRuntime) {
    Expect.isNotNull(buildId);
    Expect.isTrue(buildId!.isNotEmpty, 'Build ID is an empty string');
  } else {
    Expect.isNull(buildId); // Should be null in JIT mode.
  }
  print(buildId);
}
