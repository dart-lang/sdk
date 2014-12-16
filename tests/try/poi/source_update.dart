// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trydart.source_update;

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
  List<StringBuffer> result = new List<StringBuffer>(outputCount);
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
        throw new ArgumentError(
            "Expected ${outputCount} segments, "
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
