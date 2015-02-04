// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library pub.transcript;

import 'dart:collection';

/// A rolling transcript of entries of type [T].
///
/// It has a maximum number of entries. If entries are added that exceed that
/// it discards entries from the *middle* of the transcript. Generally, in logs,
/// the first and last entries are the most important, so it maintains those.
class Transcript<T> {
  /// The maximum number of transcript entries.
  final int max;

  /// The number of entries that were discarded after reaching [max].
  int get discarded => _discarded;
  int _discarded = 0;

  /// The earliest half of the entries.
  ///
  /// This will be empty until the maximum number of entries is hit at which
  /// point the oldest half of the entries will be moved from [_newest] to
  /// here.
  final _oldest = new List<T>();

  /// The most recent half of the entries.
  final _newest = new Queue<T>();

  /// Creates a new [Transcript] that can hold up to [max] entries.
  Transcript(this.max);

  /// Adds [entry] to the transcript.
  ///
  /// If the transcript already has the maximum number of entries, discards one
  /// from the middle.
  void add(T entry) {
    if (discarded > 0) {
      // We're already in "rolling" mode.
      _newest.removeFirst();
      _discarded++;
    } else if (_newest.length == max) {
      // We are crossing the threshold where we have to discard items. Copy
      // the first half over to the oldest list.
      while (_newest.length > max ~/ 2) {
        _oldest.add(_newest.removeFirst());
      }

      // Discard the middle item.
      _newest.removeFirst();
      _discarded++;
    }

    _newest.add(entry);
  }

  /// Traverses the entries in the transcript from oldest to newest.
  ///
  /// Invokes [onEntry] for each item. When it reaches the point in the middle
  /// where excess entries where dropped, invokes [onGap] with the number of
  /// dropped entries. If no more than [max] entries were added, does not
  /// invoke [onGap].
  void forEach(void onEntry(T entry), [void onGap(int)]) {
    if (_oldest.isNotEmpty) {
      _oldest.forEach(onEntry);
      if (onGap != null) onGap(discarded);
    }

    _newest.forEach(onEntry);
  }
}
