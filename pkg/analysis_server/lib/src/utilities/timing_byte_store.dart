// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:meta/meta.dart';

/// Totals for one kind of [ByteStore] operation.
class ByteStoreOperationTimings {
  int _count = 0;
  int _bytes = 0;
  int _elapsedMicroseconds = 0;
  int _maxMicroseconds = 0;

  new _();

  /// The number of bytes stored, or found.
  int get bytes => _bytes;

  int get count => _count;

  Duration get elapsed => Duration(microseconds: _elapsedMicroseconds);

  /// The duration of the slowest operation.
  Duration get max => Duration(microseconds: _maxMicroseconds);

  void _add(ByteStoreOperationTimings other) {
    _count += other._count;
    _bytes += other._bytes;
    _elapsedMicroseconds += other._elapsedMicroseconds;
    if (other._maxMicroseconds > _maxMicroseconds) {
      _maxMicroseconds = other._maxMicroseconds;
    }
  }

  void _record({required int bytes, required int microseconds}) {
    _count++;
    _bytes += bytes;
    _elapsedMicroseconds += microseconds;
    if (microseconds > _maxMicroseconds) {
      _maxMicroseconds = microseconds;
    }
  }
}

/// [ByteStore] operations during a period of the server's life.
class ByteStoreTimings {
  /// What started this period.
  final String reason;

  final DateTime startTime;

  /// Calls to [ByteStore.get].
  final ByteStoreOperationTimings gets = ._();

  /// Calls to [ByteStore.putGet]. The time includes any writing that the store
  /// does before returning, except reported [flushes], so that the times of
  /// operations add up. It does not include writing that the store defers or
  /// does elsewhere.
  final ByteStoreOperationTimings puts = ._();

  /// Flushes of pending values to storage, reported by the store using
  /// [TimingByteStore.recordFlush], with [ByteStoreOperationTimings.bytes] of
  /// the values, including flushes that happen inside [puts].
  final ByteStoreOperationTimings flushes = ._();

  final bool _isMilestone;

  String? _endReason;
  DateTime? _endTime;
  int _notFoundCount = 0;

  new _(this.reason, {required this._isMilestone}) : startTime = DateTime.now();

  /// The wall-clock duration of this period, so far if it is current.
  Duration get duration => (_endTime ?? DateTime.now()).difference(startTime);

  /// What ended this period, or `null` if it is current.
  String? get endReason => _endReason;

  bool get isEmpty => gets.count == 0 && puts.count == 0 && flushes.count == 0;

  /// Whether this period starts at a milestone, such as initial analysis,
  /// and so is kept forever.
  bool get isMilestone => _isMilestone;

  /// The number of [gets] that did not find a value.
  int get notFoundCount => _notFoundCount;

  void _add(ByteStoreTimings other) {
    gets._add(other.gets);
    puts._add(other.puts);
    flushes._add(other.flushes);
    _notFoundCount += other._notFoundCount;
  }
}

/// A wrapper around [ByteStore] that records operations, grouped into periods
/// of the server's life.
class TimingByteStore implements ByteStore {
  /// The maximum number of non-milestone periods to keep.
  ///
  /// The server starts a period on every analysis status change, so without a
  /// limit periods would accumulate for the whole life of the server.
  static const int _maxRecentPeriodCount = 50;

  final ByteStore _store;

  final Stopwatch _stopwatch;

  final List<ByteStoreTimings> _periods = [];

  /// The totals of the periods dropped to stay within [_maxRecentPeriodCount].
  final ByteStoreTimings _dropped = ._('dropped', isMilestone: false);

  int _droppedPeriodCount = 0;
  int _recentPeriodCount = 0;

  /// The total time of reported flushes, used to exclude the flushes that
  /// happen inside [putGet] from its time.
  int _flushMicroseconds = 0;

  late ByteStoreTimings _current;

  new(this._store, {@visibleForTesting Stopwatch? stopwatch})
    : _stopwatch = (stopwatch ?? Stopwatch())..start() {
    _startPeriod('startup', isMilestone: true);
  }

  /// The number of periods dropped from [periods], which are included only
  /// into [recentTotal] and [total].
  int get droppedPeriodCount => _droppedPeriodCount;

  /// The kept periods, from oldest to newest; the last one is current.
  List<ByteStoreTimings> get periods => UnmodifiableListView(_periods);

  /// The totals of non-milestone periods, including dropped ones.
  ByteStoreTimings get recentTotal {
    var result = ByteStoreTimings._('recent', isMilestone: false);
    result._add(_dropped);
    for (var period in _periods) {
      if (!period._isMilestone) {
        result._add(period);
      }
    }
    return result;
  }

  /// The totals since startup, including dropped periods.
  ByteStoreTimings get total {
    var result = ByteStoreTimings._('startup', isMilestone: true);
    result._add(_dropped);
    for (var period in _periods) {
      result._add(period);
    }
    return result;
  }

  @override
  Uint8List? get(String key) {
    var startMicroseconds = _stopwatch.elapsedMicroseconds;
    var result = _store.get(key);
    _current.gets._record(
      bytes: result?.length ?? 0,
      microseconds: _stopwatch.elapsedMicroseconds - startMicroseconds,
    );
    if (result == null) {
      _current._notFoundCount++;
    }
    return result;
  }

  @override
  Uint8List putGet(String key, Uint8List bytes) {
    var startMicroseconds = _stopwatch.elapsedMicroseconds;
    var startFlushMicroseconds = _flushMicroseconds;
    var result = _store.putGet(key, bytes);
    var elapsedMicroseconds =
        _stopwatch.elapsedMicroseconds - startMicroseconds;
    var flushMicroseconds = _flushMicroseconds - startFlushMicroseconds;
    _current.puts._record(
      bytes: bytes.length,
      // The store measures flushes on its own, so rounding can make them
      // slightly longer than the whole put.
      microseconds: math.max(0, elapsedMicroseconds - flushMicroseconds),
    );
    return result;
  }

  /// Records a flush of [valueBytes] of pending values that took [elapsed],
  /// into the current period.
  ///
  /// The wrapped store calls this, because it flushes on its own, including
  /// inside [putGet], when this wrapper cannot see it.
  void recordFlush(int valueBytes, Duration elapsed) {
    var microseconds = elapsed.inMicroseconds;
    _current.flushes._record(bytes: valueBytes, microseconds: microseconds);
    _flushMicroseconds += microseconds;
  }

  @override
  void release(Iterable<String> keys) => _store.release(keys);

  /// Ends the current period, and starts a new one tagged with [reason].
  ///
  /// Milestone periods, such as initial analysis, are kept forever. Other
  /// periods are discarded if empty, because most status changes are not
  /// followed by any operations. Of the rest only the most recent
  /// [_maxRecentPeriodCount] ended ones are kept; older ones are dropped, and
  /// included only into [total].
  void startPeriod(String reason, {bool isMilestone = false}) {
    if (!_current._isMilestone && _current.isEmpty) {
      _periods.removeLast();
      _recentPeriodCount--;
    } else {
      _current._endReason = reason;
      _current._endTime = DateTime.now();
    }

    if (_recentPeriodCount > _maxRecentPeriodCount) {
      var index = _periods.indexWhere((period) => !period._isMilestone);
      _dropped._add(_periods.removeAt(index));
      _droppedPeriodCount++;
      _recentPeriodCount--;
    }

    _startPeriod(reason, isMilestone: isMilestone);
  }

  void _startPeriod(String reason, {required bool isMilestone}) {
    _current = ByteStoreTimings._(reason, isMilestone: isMilestone);
    _periods.add(_current);
    if (!isMilestone) {
      _recentPeriodCount++;
    }
  }
}
