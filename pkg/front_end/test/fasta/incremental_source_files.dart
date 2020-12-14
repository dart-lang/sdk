// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library fasta.test.incremental_source_files;

/// Expand a file with diffs in common merge conflict format into a [List] that
/// can be passed to [expandUpdates].
///
/// For example:
///     first
///     <<<<
///     v1
///     ====
///     v2
///     ====
///     v3
///     >>>>
///     last
///
/// Would be expanded to something equivalent to:
///
///     ["first\n", ["v1\n", "v2\n", "v3\n"], "last\n"]
List expandDiff(String text) {
  List result = [new StringBuffer()];
  bool inDiff = false;
  for (String line in splitLines(text)) {
    if (inDiff) {
      if (line.startsWith("====")) {
        result.last.add(new StringBuffer());
      } else if (line.startsWith(">>>>")) {
        inDiff = false;
        result.add(new StringBuffer());
      } else {
        result.last.last.write(line);
      }
    } else if (line.startsWith("<<<<")) {
      inDiff = true;
      result.add(<StringBuffer>[new StringBuffer()]);
    } else {
      result.last.write(line);
    }
  }
  return result;
}

/// Returns [updates] expanded to full compilation units/source files.
///
/// [updates] is a convenient way to write updates/patches to a single source
/// file without repeating common parts.
///
/// For example:
///   ["head ", ["v1", "v2"], " tail"]
/// expands to:
///   ["head v1 tail", "head v2 tail"]
List<String> expandUpdates(List updates) {
  int outputCount = updates.firstWhere((e) => e is Iterable).length;
  List<StringBuffer> result = new List<StringBuffer>.filled(outputCount, null);
  for (int i = 0; i < outputCount; i++) {
    result[i] = new StringBuffer();
  }
  for (var chunk in updates) {
    if (chunk is Iterable) {
      int segmentCount = 0;
      for (var segment in chunk) {
        result[segmentCount++].write(segment);
      }
      if (segmentCount != outputCount) {
        throw new ArgumentError("Expected ${outputCount} segments, "
            "but found ${segmentCount} in $chunk");
      }
    } else {
      for (StringBuffer buffer in result) {
        buffer.write(chunk);
      }
    }
  }

  return result.map((e) => '$e').toList();
}

/// Split [text] into lines preserving trailing newlines (unlike
/// String.split("\n"). Also, if [text] is empty, return an empty list (unlike
/// String.split("\n")).
List<String> splitLines(String text) {
  return text.split(new RegExp('^', multiLine: true));
}
