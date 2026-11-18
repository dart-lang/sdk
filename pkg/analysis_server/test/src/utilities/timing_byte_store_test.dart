// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:typed_data';

import 'package:analysis_server/src/utilities/timing_byte_store.dart';
import 'package:analyzer/src/dart/analysis/byte_store.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TimingByteStoreTest);
  });
}

@reflectiveTest
class TimingByteStoreTest {
  final TimingByteStore store = TimingByteStore(MemoryByteStore());

  void test_get() {
    store.putGet('a', Uint8List(3));

    expect(store.get('a'), hasLength(3));
    expect(store.get('b'), isNull);

    var lookups = store.periods.single.lookups;
    expect(lookups.count, 2);
    expect(lookups.bytes, 3);
    expect(lookups.max, lessThanOrEqualTo(lookups.elapsed));
    expect(store.periods.single.notFoundCount, 1);
  }

  void test_putGet() {
    store.putGet('a', Uint8List(3));
    store.putGet('b', Uint8List(5));

    expect(store.get('b'), hasLength(5));
    var puts = store.periods.single.puts;
    expect(puts.count, 2);
    expect(puts.bytes, 8);
    expect(puts.max, lessThanOrEqualTo(puts.elapsed));
  }

  void test_recentTotal() {
    store.putGet('a', Uint8List(3));
    store.startPeriod('contexts created', isMilestone: true);
    store.get('a');
    for (var i = 0; i < 60; i++) {
      store.startPeriod('analysis');
      store.putGet('b', Uint8List(5));
    }

    // Only non-milestone periods; some were dropped, but are still included.
    expect(store.droppedPeriodCount, isPositive);
    var recentTotal = store.recentTotal;
    expect(recentTotal.lookups.count, 0);
    expect(recentTotal.puts.count, 60);
    expect(recentTotal.puts.bytes, 300);
  }

  void test_startPeriod() {
    store.putGet('a', Uint8List(3));
    store.startPeriod('contexts created', isMilestone: true);
    store.get('a');
    store.get('b');

    var periods = store.periods;
    expect(periods, hasLength(2));

    expect(periods[0].reason, 'startup');
    expect(periods[0].endReason, 'contexts created');
    expect(periods[0].puts.count, 1);
    expect(periods[0].lookups.count, 0);

    expect(periods[1].reason, 'contexts created');
    expect(periods[1].endReason, isNull);
    expect(periods[1].puts.count, 0);
    expect(periods[1].lookups.count, 2);
    expect(periods[1].notFoundCount, 1);
  }

  void test_startPeriod_discardedPeriod_keepsEndReason() {
    store.startPeriod('analysis');
    store.putGet('a', Uint8List(1));
    store.startPeriod('idle');
    store.startPeriod('analysis');

    var periods = store.periods;
    expect(periods.map((period) => period.reason), [
      'startup',
      'analysis',
      'analysis',
    ]);
    expect(periods[1].endReason, 'idle');
  }

  void test_startPeriod_discardsEmptyPeriod() {
    store.startPeriod('analysis');
    store.startPeriod('idle');

    expect(store.periods.map((period) => period.reason), ['startup', 'idle']);
    expect(store.droppedPeriodCount, 0);
  }

  void test_startPeriod_dropsOldestRecentPeriods() {
    for (var i = 0; i < 30; i++) {
      store.startPeriod('recent $i');
      store.putGet('a', Uint8List(1));
      store.startPeriod('empty');
    }
    store.startPeriod('contexts created', isMilestone: true);
    for (var i = 30; i < 60; i++) {
      store.startPeriod('recent $i');
      store.putGet('a', Uint8List(1));
      store.startPeriod('empty');
    }

    // Milestones are kept, and of other periods only the 50 most recent
    // non-empty ones, and the current one.
    var reasons = store.periods.map((period) => period.reason).toList();
    expect(reasons, [
      'startup',
      for (var i = 10; i < 30; i++) 'recent $i',
      'contexts created',
      for (var i = 30; i < 60; i++) 'recent $i',
      'empty',
    ]);
    expect(store.droppedPeriodCount, 10);

    // Dropped periods are still included into the total.
    expect(store.total.puts.count, 60);
  }

  void test_startPeriod_keepsEmptyCurrentPeriod() {
    store.startPeriod('analysis');
    store.putGet('a', Uint8List(1));
    store.startPeriod('idle');

    expect(store.periods.map((period) => period.reason), [
      'startup',
      'analysis',
      'idle',
    ]);
  }

  void test_startPeriod_keepsEmptyMilestone() {
    store.startPeriod('contexts created', isMilestone: true);
    store.startPeriod('initial analysis completed', isMilestone: true);
    store.startPeriod('analysis');

    expect(store.periods.map((period) => period.reason), [
      'startup',
      'contexts created',
      'initial analysis completed',
      'analysis',
    ]);
  }

  void test_total() {
    store.putGet('a', Uint8List(3));
    store.startPeriod('analysis');
    store.get('a');
    store.get('b');
    store.startPeriod('idle');
    store.putGet('b', Uint8List(5));

    var total = store.total;
    expect(total.lookups.count, 2);
    expect(total.lookups.bytes, 3);
    expect(total.notFoundCount, 1);
    expect(total.puts.count, 2);
    expect(total.puts.bytes, 8);
  }
}
