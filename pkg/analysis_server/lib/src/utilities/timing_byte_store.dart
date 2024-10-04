// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// @docImport 'package:analyzer/src/dart/analysis/file_byte_store.dart';
library;

import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/byte_store.dart';

class ByteStoreTimings {
  final DateTime time;
  final String reason;
  final _readTime = Stopwatch();
  var _readCount = 0;

  ByteStoreTimings(this.reason) : time = DateTime.now();

  int get readCount => _readCount;
  Duration get readTime => _readTime.elapsed;
}

/// A wrapper around [ByteStore] which records the time spend reading items.
///
/// Wrapping this around a [FileByteStore] will allow monitoring the performance
/// of reading files from disk.
class TimingByteStore implements ByteStore {
  final ByteStore _store;

  /// A list of all timing buckets that have been collected.
  late final List<ByteStoreTimings> timings = [_current];

  /// The current bucket to record times into.
  var _current = ByteStoreTimings('startup');

  TimingByteStore(this._store);

  @override
  Uint8List? get(String key) {
    var times = _current;
    times._readCount++;
    times._readTime.start();
    try {
      return _store.get(key);
    } finally {
      times._readTime.stop();
    }
  }

  /// Creates a new [ByteStoreTimings] to record future reads, tagged with a
  /// [reason].
  void newTimings(String reason) {
    timings.add(_current = ByteStoreTimings(reason));
  }

  @override
  Uint8List putGet(String key, Uint8List bytes) => _store.putGet(key, bytes);

  @override
  void release(Iterable<String> keys) => _store.release(keys);
}
