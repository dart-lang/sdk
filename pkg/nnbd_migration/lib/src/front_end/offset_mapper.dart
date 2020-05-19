// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';

/// An object that can map the offsets before a sequence of edits to the offsets
/// after applying the edits.
abstract class OffsetMapper {
  /// A mapper used for files that were not modified.
  static OffsetMapper identity = _IdentityMapper();

  /// Return a mapper representing the file modified by the given [edits].
  factory OffsetMapper.forEdits(List<SourceEdit> edits) => _EditMapper(edits);

  /// Return a mapper representing the file modified by an insertion at [offset]
  /// the given with [length].
  factory OffsetMapper.forInsertion(int offset, int length) =>
      _SimpleSourceEditMapper(offset, 0, length);

  /// Return a mapper representing the file modified by an insertion at [offset]
  /// with [replacemnet] text overwriting the given [length].
  factory OffsetMapper.forReplacement(
          int offset, int length, String replacement) =>
      _SimpleSourceEditMapper(offset, length, replacement.length);

  /// Return a mapper representing [rebased] rebased by [rebaser].
  ///
  /// Warning: this does not currently handle cases where the [rebased] mapper
  /// contains an insert or deletion in the middle of a range deleted by
  /// [rebaser]. This is not a case that currently needs to be supported.
  factory OffsetMapper.rebase(OffsetMapper rebaser, OffsetMapper rebased) {
    return _RebasedOffsetMapper(rebaser, rebased);
  }

  /// Return a mapper representing a sequence of edits made in order, with the
  /// offsets coming out of [first] being the offsets passed into [second].
  factory OffsetMapper.sequence(OffsetMapper first, OffsetMapper second) {
    return _OffsetMapperChain([first, second]);
  }

  /// Return the post-edit offset that corresponds to the given pre-edit
  /// [offset], or `null` when that offset has been deleted.
  int map(int offset);
}

/// A mapper used for files that were modified by a set of edits.
class _EditMapper implements OffsetMapper {
  /// A list whose elements are the highest pre-edit offset for which the
  /// corresponding element of [_deltas] should be applied.
  final List<int> _offsets = [];

  /// A list whose elements are the deltas to be applied for all pre-edit
  /// offsets that are less than or equal to the corresponding element of
  /// [_offsets].
  final List<int> _deltas = [];

  /// Initialize a newly created mapper based on the given set of [edits].
  _EditMapper(List<SourceEdit> edits) {
    _initializeDeltas(edits);
  }

  @override
  int map(int offset) => offset + _deltaFor(offset);

  /// Return the delta to be added to the pre-edit [offset] to produce the
  /// post-edit offset.
  int _deltaFor(int offset) {
    for (var i = 0; i < _offsets.length; i++) {
      var currentOffset = _offsets[i];
      if (currentOffset >= offset || currentOffset < 0) {
        return _deltas[i];
      }
    }
    // We should never get here because [_initializeDeltas] always adds an
    // offset/delta pair at the end of the list whose offset is less than zero.
    return 0;
  }

  /// Initialize the list of old offsets and deltas used by [_deltaFor].
  void _initializeDeltas(List<SourceEdit> edits) {
    var previousDelta = 0;
    for (var edit in edits) {
      var offset = edit.offset;
      var length = edit.length;
      _offsets.add(offset);
      _deltas.add(previousDelta);
      previousDelta += (edit.replacement.length - length);
    }
    _offsets.add(-1);
    _deltas.add(previousDelta);
  }
}

/// A mapper used for files that were not modified.
class _IdentityMapper implements OffsetMapper {
  @override
  int map(int offset) => offset;
}

class _OffsetMapperChain implements OffsetMapper {
  final List<OffsetMapper> innerMappers;

  _OffsetMapperChain(this.innerMappers);

  @override
  int map(int offset) {
    for (final mapper in innerMappers) {
      offset = mapper.map(offset);
      if (offset == null) {
        break;
      }
    }
    return offset;
  }
}

class _RebasedOffsetMapper implements OffsetMapper {
  final OffsetMapper rebaser;
  final OffsetMapper rebased;

  _RebasedOffsetMapper(this.rebaser, this.rebased);

  @override
  int map(int offset) {
    final rebasedOffset = rebased.map(offset);
    final rebasingOffset = rebaser.map(offset);
    if (rebasedOffset == null || rebasingOffset == null) {
      return null;
    }
    final delta = rebasedOffset - offset;
    return rebasingOffset + delta;
  }
}

class _SimpleSourceEditMapper implements OffsetMapper {
  /// The offset where the replacement begins.
  final int offset;

  /// The length of text to be replaced.
  final int replacedLength;

  /// The length of text to be inserted as a replacement.
  final int replacementLength;

  _SimpleSourceEditMapper(
      this.offset, this.replacedLength, this.replacementLength);

  @override
  int map(int offset) {
    if (offset < this.offset) {
      return offset;
    }
    if (offset < this.offset + replacedLength) {
      return null;
    }
    return offset + replacementLength - replacedLength;
  }
}
