// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Defines [StringEditBuffer], a buffer that can be used to apply edits on a
/// string.
// TODO(sigmund): this should move to a separate package.
library dart2js.src.string_edit_buffer;

/// A buffer meant to apply edits on a string (rather than building a string
/// from scratch). Each change is described using the location information on
/// the original string. Internally this buffer keeps track of how a
/// modification in one portion can offset a modification further down the
/// string.
class StringEditBuffer {
  final String original;
  final _edits = <_StringEdit>[];

  StringEditBuffer(this.original);

  bool get hasEdits => _edits.length > 0;

  /// Edit the original text, replacing text on the range [begin] and
  /// exclusive [end] with the [replacement] string.
  void replace(int begin, int end, String replacement, [int sortId]) {
    _edits.add(new _StringEdit(begin, end, replacement, sortId));
  }

  /// Insert [string] at [offset].
  /// Equivalent to `replace(offset, offset, string)`.
  void insert(int offset, String string, [sortId]) =>
      replace(offset, offset, string, sortId);

  /// Remove text from the range [begin] to exclusive [end].
  /// Equivalent to `replace(begin, end, '')`.
  void remove(int begin, int end) => replace(begin, end, '');

  /// Applies all pending [edit]s and returns a new string.
  ///
  /// This method is non-destructive: it does not discard existing edits or
  /// change the [original] string. Further edits can be added and this method
  /// can be called again.
  ///
  /// Throws [UnsupportedError] if the edits were overlapping. If no edits were
  /// made, the original string will be returned.
  String toString() {
    var sb = new StringBuffer();
    if (_edits.length == 0) return original;

    // Sort edits by start location.
    _edits.sort();

    int consumed = 0;
    for (var edit in _edits) {
      if (consumed > edit.begin) {
        sb = new StringBuffer();
        sb.write('overlapping edits. Insert at offset ');
        sb.write(edit.begin);
        sb.write(' but have consumed ');
        sb.write(consumed);
        sb.write(' input characters. List of edits:');
        for (var e in _edits) {
          sb.write('\n    ');
          sb.write(e);
        }
        throw new UnsupportedError(sb.toString());
      }

      // Add characters from the original string between this edit and the last
      // one, if any.
      var betweenEdits = original.substring(consumed, edit.begin);
      sb.write(betweenEdits);
      sb.write(edit.string);
      consumed = edit.end;
    }

    // Add any text from the end of the original string that was not replaced.
    sb.write(original.substring(consumed));
    return sb.toString();
  }
}

/// A single edit in a [StringEditBuffer].
class _StringEdit implements Comparable<_StringEdit> {
  // Offset where edit begins
  final int begin;

  // Offset where edit ends
  final int end;

  // Sort index as a tie-breaker for edits that have the same location.
  final int sortId;

  // String to insert
  final String string;

  _StringEdit(int begin, this.end, this.string, [int sortId])
      : begin = begin,
        sortId = sortId == null ? begin : sortId;

  int get length => end - begin;

  String toString() => '(Edit @ $begin,$end: "$string")';

  int compareTo(_StringEdit other) {
    int diff = begin - other.begin;
    if (diff != 0) return diff;
    diff = end - other.end;
    if (diff != 0) return diff;
    // use edit order as a tie breaker
    return sortId - other.sortId;
  }
}
