// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Represents a mapping from a range of generated instructions to some source
/// code.
class SourceMapping {
  /// Start offset of mapped instructions.
  final int instructionOffset;

  /// Source info for the mapped instructions starting at [instructionOffset].
  ///
  /// When `null`, the mapping effectively makes the code unmapped. This is
  /// useful for compiler-generated code that doesn't correstpond to any lines
  /// in the source.
  final SourceInfo? sourceInfo;

  SourceMapping._(this.instructionOffset, this.sourceInfo);

  SourceMapping(
      this.instructionOffset, Uri fileUri, int line, int col, String? name)
      : sourceInfo = SourceInfo(fileUri, line, col, name);

  SourceMapping.unmapped(this.instructionOffset) : sourceInfo = null;

  @override
  String toString() => '$instructionOffset -> $sourceInfo';
}

class SourceInfo {
  /// URI of the compiled code's file.
  final Uri fileUri;

  /// 0-based line number of the compiled code.
  final int line;

  /// 0-based column number of the compiled code.
  final int col;

  /// Name of the mapped code. This is usually the name of the function that
  /// contains the code.
  final String? name;

  SourceInfo(this.fileUri, this.line, this.col, this.name);

  @override
  String toString() => '$fileUri:$line:$col ($name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    if (other is! SourceInfo) {
      return false;
    }

    return fileUri == other.fileUri &&
        line == other.line &&
        col == other.col &&
        name == other.name;
  }

  @override
  int get hashCode => Object.hash(fileUri, line, col, name);
}

class SourceMapSerializer {
  final List<SourceMapping> mappings = [];

  void addMapping(int instructionOffset, SourceInfo? sourceInfo) {
    final mapping = SourceMapping._(instructionOffset, sourceInfo);
    mappings.add(mapping);
  }

  void copyMappings(SourceMapSerializer other, int offset) {
    for (final mapping in other.mappings) {
      mappings.add(SourceMapping._(
        mapping.instructionOffset + offset,
        mapping.sourceInfo,
      ));
    }
  }

  String serialize() => _serializeSourceMap(mappings);
}

String _serializeSourceMap(List<SourceMapping> mappings) {
  final Set<Uri> sourcesSet = {};
  for (final mapping in mappings) {
    if (mapping.sourceInfo?.fileUri != null) {
      sourcesSet.add(mapping.sourceInfo!.fileUri);
    }
  }

  final List<Uri> sourcesList = sourcesSet.toList();

  // Maps sources to their indices in the 'sources' list.
  final Map<Uri, int> sourceIndices = {};
  for (Uri source in sourcesList) {
    sourceIndices[source] = sourceIndices.length;
  }

  final Set<String> namesSet = {};
  for (final mapping in mappings) {
    if (mapping.sourceInfo?.name != null) {
      namesSet.add(mapping.sourceInfo!.name!);
    }
  }

  final List<String> namesList = namesSet.toList();

  // Maps names to their index in the 'names' list.
  final Map<String, int> nameIndices = {};
  for (String name in namesList) {
    nameIndices[name] = nameIndices.length;
  }

  // Generate the 'mappings' field.
  final StringBuffer mappingsStr = StringBuffer();

  int lastTargetColumn = 0;
  int lastSourceIndex = 0;
  int lastSourceLine = 0;
  int lastSourceColumn = 0;
  int lastNameIndex = 0;

  bool first = true;

  for (int i = 0; i < mappings.length; ++i) {
    final mapping = mappings[i];
    final sourceInfo = mapping.sourceInfo;

    if (sourceInfo == null && first) {
      // Initial parts of the code will be unmapped my default, we don't need to
      // explicitly unmap them. More importantly, current version of binaryen
      // cannot handle single-segment mappings at the beginning of the mappings.
      // We can remove this block of code after switching to a version with
      // https://github.com/WebAssembly/binaryen/pull/6794.
      continue;
    }

    first = false;

    lastTargetColumn =
        _encodeVLQ(mappingsStr, mapping.instructionOffset, lastTargetColumn);

    if (sourceInfo != null) {
      final sourceIndex = sourceIndices[sourceInfo.fileUri]!;

      lastSourceIndex = _encodeVLQ(mappingsStr, sourceIndex, lastSourceIndex);
      lastSourceLine = _encodeVLQ(mappingsStr, sourceInfo.line, lastSourceLine);
      lastSourceColumn =
          _encodeVLQ(mappingsStr, sourceInfo.col, lastSourceColumn);

      if (sourceInfo.name != null) {
        final nameIndex = nameIndices[sourceInfo.name!]!;
        lastNameIndex = _encodeVLQ(mappingsStr, nameIndex, lastNameIndex);
      }
    }

    if (i != mappings.length - 1) {
      mappingsStr.write(',');
    }
  }

  return """{
      "version": 3,
      "sources": [${sourcesList.map((source) => '"$source"').join(",")}],
      "names": [${namesList.map((name) => '"$name"').join(",")}],
      "mappings": "$mappingsStr"
  }""";
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
const String _base64Digits = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmn'
    'opqrstuvwxyz0123456789+/';
