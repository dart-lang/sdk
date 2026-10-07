// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:source_maps/parser.dart';

import 'debug_info.dart';

export 'debug_info.dart';

/// Builder that collects function-level byte debug info during serialization
/// and generates Source Map v3 JSON.
class SourceMapBuilder implements DebugInfoSerializer {
  final DebugInfoTables? debugInfoTables;
  final List<(int, Uint8List)> _functions = [];
  int? _codeSectionFileOffset;

  SourceMapBuilder(this.debugInfoTables);

  @override
  void addFunction(int functionCodeOffset, Uint8List byteDebugInfo) {
    if (byteDebugInfo.isNotEmpty) {
      _functions.add((functionCodeOffset, byteDebugInfo));
    }
  }

  @override
  void setCodeSectionFileOffset(int fileOffset) {
    _codeSectionFileOffset = fileOffset;
  }

  Map<String, Object?> toJson() {
    final filesInfo = debugInfoTables;
    if (filesInfo == null || _functions.isEmpty) {
      return <String, Object?>{
        "version": 3,
        "sources":
            filesInfo?.files.map((uri) => uri.toString()).toList() ??
            const <String>[],
        "names": filesInfo?.names ?? const <String>[],
        "mappings": "",
      };
    }

    final codeSectionFileOffset = _codeSectionFileOffset!;
    final StringBuffer mappingsStr = StringBuffer();

    int lastTargetColumn = 0;
    int lastSourceIndex = 0;
    int lastSourceLine = 0;
    int lastSourceColumn = 0;
    int lastNameIndex = 0;
    bool firstSegment = true;

    for (final (functionCodeOffset, byteDebugInfo) in _functions) {
      final baseOffset = codeSectionFileOffset + functionCodeOffset;
      final reader = DebugInfoReader(byteDebugInfo);

      while (reader.moveNext()) {
        if (!firstSegment) {
          mappingsStr.write(',');
        }
        firstSegment = false;

        final targetOffset = baseOffset + reader.offset;

        lastTargetColumn = _encodeVLQ(
          mappingsStr,
          targetOffset,
          lastTargetColumn,
        );

        if (reader.hasSourcePosition) {
          lastSourceIndex = _encodeVLQ(
            mappingsStr,
            reader.fileIndex,
            lastSourceIndex,
          );
          lastSourceLine = _encodeVLQ(mappingsStr, reader.line, lastSourceLine);
          lastSourceColumn = _encodeVLQ(
            mappingsStr,
            reader.col,
            lastSourceColumn,
          );

          if (reader.nameIndex >= 0) {
            lastNameIndex = _encodeVLQ(
              mappingsStr,
              reader.nameIndex,
              lastNameIndex,
            );
          }
        }
      }
    }

    return <String, Object?>{
      "version": 3,
      "sources": filesInfo.files.map((uri) => uri.toString()).toList(),
      "names": filesInfo.names,
      "mappings": mappingsStr.toString(),
    };
  }
}

/// Streaming decoder that decodes Source Map v3 JSON into instruction-level
/// debug info during Wasm module deserialization.
class SourceMapDecoder implements DebugInfoDeserializer {
  @override
  final DebugInfoTables debugInfoTables;

  final SingleMapping _mapping;
  int _entryIdx = 0;

  DebugInfoWriter? _writer;
  int? _pendingInstructionIndex;

  SourceMapDecoder(this.debugInfoTables, this._mapping);

  factory SourceMapDecoder.fromJson(Map<String, dynamic> json) {
    final mapping = SingleMapping.fromJson(json);
    final debugInfoTables = DebugInfoTables();
    for (final url in mapping.urls) {
      debugInfoTables.files.add(Uri.parse(url));
    }
    debugInfoTables.names.addAll(mapping.names);
    return SourceMapDecoder(debugInfoTables, mapping);
  }

  List<TargetEntry> get _entries =>
      _mapping.lines.isNotEmpty ? _mapping.lines[0].entries : const [];

  @override
  void startFunction(int fileOffset) {
    _writer = DebugInfoWriter(debugInfoTables);
    _pendingInstructionIndex = null;
    final entries = _entries;
    while (_entryIdx < entries.length &&
        entries[_entryIdx].column < fileOffset) {
      _entryIdx++;
    }
  }

  @override
  void onInstruction(int instructionIndex, int fileOffset) {
    if (_pendingInstructionIndex != null) {
      // Process entries that belong to the previous instruction
      _flushEntriesUpTo(fileOffset, _pendingInstructionIndex!);
    }
    _pendingInstructionIndex = instructionIndex;
  }

  @override
  Uint8List? endFunction(int fileOffset) {
    if (_pendingInstructionIndex != null) {
      // Process entries for the last instruction in the function
      _flushEntriesUpTo(fileOffset, _pendingInstructionIndex!);
      _pendingInstructionIndex = null;
    }
    final writer = _writer;
    _writer = null;
    if (writer == null || writer.isEmpty) return null;
    return writer.build();
  }

  void _flushEntriesUpTo(int limitFileOffset, int instructionIndex) {
    final writer = _writer!;
    final entries = _entries;
    while (_entryIdx < entries.length &&
        entries[_entryIdx].column < limitFileOffset) {
      final entry = entries[_entryIdx];
      if (entry.sourceUrlId != null) {
        writer.setSourcePositionWithIndices(
          instructionIndex,
          entry.sourceUrlId!,
          entry.sourceLine!,
          entry.sourceColumn!,
          entry.sourceNameId ?? -1,
        );
      } else {
        writer.clearSourcePosition(instructionIndex);
      }
      _entryIdx++;
    }
  }
}

/// Writes the VLQ of delta between [value] and [offset] into [output] and
/// return [value].
int _encodeVLQ(StringSink output, int value, int offset) {
  int delta = value - offset;
  int signBit = 0;
  if (delta < 0) {
    signBit = 1;
    delta = -delta;
  }
  delta = (delta << 1) | signBit;
  do {
    int digit = delta & _vlqBaseMask;
    delta >>= _vlqBaseShift;
    if (delta > 0) {
      digit |= _vlqContinuationBit;
    }
    output.write(_base64Digits[digit]);
  } while (delta > 0);
  return value;
}

const int _vlqBaseShift = 5;
const int _vlqBaseMask = (1 << 5) - 1;
const int _vlqContinuationBit = 1 << 5;
const String _base64Digits =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmn'
    'opqrstuvwxyz0123456789+/';
