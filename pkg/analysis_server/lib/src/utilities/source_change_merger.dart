// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:collection/collection.dart';

/// A helper to merge [SourceFileEdit]s that may have been made in multiple
/// steps.
///
/// Edits to be merged must meet some criteria:
///
/// - Multiple [SourceFileEdit]s for the same file are assumed to be in order
///   and each one assumes any earlier [SourceFileEdit] has been applied.
/// - All edits within a [SourceFileEdit] are sorted from highest to lowest
///   offsets so that there is no ambiguity about how one edit may affect the
///   range of another.
class SourceChangeMerger {
  /// A buffer that contains debug information about the re-ordering and merging
  /// of edits.
  ///
  /// This can be used in tests to provide more details about failures.
  final StringBuffer? debugBuffer;

  SourceChangeMerger({this.debugBuffer});

  /// Merges a set of edits in-place.
  List<SourceFileEdit> merge(List<SourceFileEdit> edits) {
    var results = <SourceFileEdit>[];

    for (var entry in edits.groupListsBy((edit) => edit.file).entries) {
      var file = entry.key;
      var editLists = entry.value;

      // If this file only had a single set of edits, we don't need to do
      // anything.
      if (editLists.length == 1) {
        results.add(editLists.single);
        continue;
      }

      // Flatten all sets into a single set of edits. Because we know all
      // lists and edits can be applied sequentially this is safe, however it
      // can lose the property of all edits being ordered last-to-first which is
      // something we will fix as part of sorting/merging.
      var edits = editLists.expand((edits) => edits.edits).toList();

      debugBuffer?.writeln(file);
      _debugEdits('Original', edits);

      _reorder(edits);
      _debugEdits('Reordered', edits);

      _merge(edits);
      _debugEdits('Merged', edits);

      results.add(
        SourceFileEdit(file, editLists.first.fileStamp, edits: edits),
      );
    }

    return results;
  }

  /// Writes [edits] into [debugBuffer] for debugging.
  void _debugEdits(String editKind, List<SourceEdit> edits) {
    var debugBuffer = this.debugBuffer;
    if (debugBuffer == null) {
      return;
    }

    debugBuffer.writeln('$editKind edits:');
    for (var edit in edits) {
      debugBuffer.writeln('   $edit');
    }
    debugBuffer.writeln();
  }

  /// Merges (in-place) any sequential edits that are overlapping or touching.
  ///
  /// Overlapping/touching edits will be replaced with new edits that have the
  /// same effect as applying the original edits sequentially to the source
  /// string.
  void _merge(List<SourceEdit> edits) {
    for (var i = 0; i < edits.length - 1; i++) {
      // "first" refers to position in the list (and order they were intended to
      // be sequentially applied) and not necessarily offset/source order. Most
      // edits will be in reverse order in the list.
      var first = edits[i];
      var second = edits[i + 1];

      if (second.end < first.offset) {
        // Since we know non-intersecting/touching edits are ordered correctly,
        // the second one ending before the start of the first one means it does
        // not require merging.
        continue;
      }

      // Replace the first edit with a merged version and remove the second.
      edits[i] = _mergeEdits(first, second);
      edits.removeAt(i + 1);
      i--; // Process this one again in case it also overlaps the next one.
    }
  }

  /// Merges [first] and [second] into a new [SourceEdit] that has the same
  /// effect as applying [first] then [second] sequentially to the source
  /// string.
  SourceEdit _mergeEdits(SourceEdit first, SourceEdit second) {
    // "first" refers to position in the list (and order they were intended to
    // be sequentially applied) and not necessarily offset/source order. Most
    // edits will be in reverse order in the list.

    var actualStart = math.min(first.offset, second.offset);
    var actualEnd = math.max(first.end, second.end - first.delta);
    var length = actualEnd - actualStart;

    // The new replacement text is made up of three possible parts:
    // 1. The start of first that is not replaced by second (prefix)
    // 2. The text from second (middle)
    // 3. The end of first that is not replaced by second (suffix)
    var prefix =
        second.offset > first.offset
            ? first.replacement.substring(0, second.offset - first.offset)
            : '';
    var middle = second.replacement;
    var suffix =
        second.end < first.offset + first.replacement.length
            ? first.replacement.substring(second.end - first.offset)
            : '';

    return SourceEdit(actualStart, length, '$prefix$middle$suffix');
  }

  /// Re-orders edits (in-place) so that they are from latest offset to earliest
  /// offset except in the case where they touch or intersect.
  ///
  /// Edits that are moved will be replaced by new edits with updated offsets
  /// to preserve the same behaviour when applying edits sequentially.
  ///
  /// Edits that touch or intersect will not be reordered, but will end up
  /// adjacent because other edits will be moved around them.
  void _reorder(List<SourceEdit> edits) {
    // This is essentially an in-place insertion sort, but the edits are mutated
    // as they are swapped to preserve behaviour.
    for (var i = 1; i < edits.length; i++) {
      var current = edits[i];
      var j = i - 1;
      // If the current edit starts after the j edit, we should swap
      // it to bring it earlier.
      while (j >= 0 && current.offset >= edits[j].end + edits[j].delta) {
        // Because edits[j] will no longer be applied before us and we know it
        // would have been applied earlier in the file, we need to adjust our
        // offset by its delta.
        // If we need to change the offset, we must create a new edit and not
        // mutate the original.
        current = SourceEdit(
          current.offset - edits[j].delta,
          current.length,
          current.replacement,
        );
        edits[j + 1] = edits[j];
        j--;
      }
      edits[j + 1] = current;
    }
  }
}

extension on SourceEdit {
  int get delta => replacement.length - length;
}
