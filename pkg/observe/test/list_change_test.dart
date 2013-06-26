// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

// This file contains code ported from:
// https://github.com/rafaelw/ChangeSummary/blob/master/tests/test.js

main() {
  // TODO(jmesserly): rename this? Is summarizeListChanges coming back?
  group('summarizeListChanges', listChangeTests);
}

// TODO(jmesserly): port or write array fuzzer tests
listChangeTests() {

  test('sequential adds', () {
    var model = toObservable([]);
    model.add(0);

    var summary;
    var sub = model.changes.listen((r) { summary = _filter(r); });

    model.add(1);
    model.add(2);

    expect(summary, null);
    deliverChangeRecords();

    expectChanges(summary, [_delta(1, 0, 2)]);
  });

  test('List Splice Truncate And Expand With Length', () {
    var model = toObservable(['a', 'b', 'c', 'd', 'e']);

    var summary;
    var sub = model.changes.listen((r) { summary = _filter(r); });

    model.length = 2;

    deliverChangeRecords();
    expectChanges(summary, [_delta(2, 3, 0)]);
    summary = null;

    model.length = 5;

    deliverChangeRecords();
    expectChanges(summary, [_delta(2, 0, 3)]);
  });

  group('List deltas can be applied', () {

    var summary = null;

    observeArray(model) {
      model.changes.listen((records) { summary = _filter(records); });
    }

    applyAndCheckDeltas(model, copy) {
      summary = null;
      deliverChangeRecords();

      // apply deltas to the copy
      for (var delta in summary) {
        copy.removeRange(delta.index, delta.index + delta.removedCount);
        for (int i = delta.addedCount - 1; i >= 0; i--) {
          copy.insert(delta.index, model[delta.index + i]);
        }
      }

      // Note: compare strings for easier debugging.
      expect('$copy', '$model', reason: '!!! summary $summary');
    }

    test('Contained', () {
      var model = toObservable(['a', 'b']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(1);
      model.insertAll(0, ['c', 'd', 'e']);
      model.removeRange(1, 3);
      model.insert(1, 'f');

      applyAndCheckDeltas(model, copy);
    });

    test('Delete Empty', () {
      var model = toObservable([1]);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(0);
      model.insertAll(0, ['a', 'b', 'c']);

      applyAndCheckDeltas(model, copy);
    });

    test('Right Non Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeRange(0, 1);
      model.insert(0, 'e');
      model.removeRange(2, 3);
      model.insertAll(2, ['f', 'g']);

      applyAndCheckDeltas(model, copy);
    });

    test('Left Non Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeRange(3, 4);
      model.insertAll(3, ['f', 'g']);
      model.removeRange(0, 1);
      model.insert(0, 'e');

      applyAndCheckDeltas(model, copy);
    });

    test('Right Adjacent', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeRange(1, 2);
      model.insert(3, 'e');
      model.removeRange(2, 3);
      model.insertAll(0, ['f', 'g']);

      applyAndCheckDeltas(model, copy);
    });

    test('Left Adjacent', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeRange(2, 4);
      model.insert(2, 'e');

      model.removeAt(1);
      model.insertAll(1, ['f', 'g']);

      applyAndCheckDeltas(model, copy);
    });

    test('Right Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(1);
      model.insert(1, 'e');
      model.removeAt(1);
      model.insertAll(1, ['f', 'g']);

      applyAndCheckDeltas(model, copy);
    });

    test('Left Overlap', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(2);
      model.insertAll(2, ['e', 'f', 'g']);
      // a b [e f g] d
      model.removeRange(1, 3);
      model.insertAll(1, ['h', 'i', 'j']);
      // a [h i j] f g d

      applyAndCheckDeltas(model, copy);
    });

    test('Prefix And Suffix One In', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.insert(0, 'z');
      model.add('z');

      applyAndCheckDeltas(model, copy);
    });

    test('Remove First', () {
      var model = toObservable([16, 15, 15]);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(0);

      applyAndCheckDeltas(model, copy);
    });

    test('Update Remove', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(2);
      model.insertAll(2, ['e', 'f', 'g']);  // a b [e f g] d
      model[0] = 'h';
      model.removeAt(1);

      applyAndCheckDeltas(model, copy);
    });

    test('Remove Mid List', () {
      var model = toObservable(['a', 'b', 'c', 'd']);
      var copy = model.toList();
      observeArray(model);

      model.removeAt(2);

      applyAndCheckDeltas(model, copy);
    });
  });

  group('edit distance', () {
    var summary = null;

    observeArray(model) {
      model.changes.listen((records) { summary = _filter(records); });
    }

    assertEditDistance(orig, expectDistance) {
      summary = null;
      deliverChangeRecords();
      var actualDistance = 0;

      if (summary != null) {
        for (var delta in summary) {
          actualDistance += delta.addedCount + delta.removedCount;
        }
      }

      expect(actualDistance, expectDistance);
    }

    test('add items', () {
      var model = toObservable([]);
      observeArray(model);
      model.addAll([1, 2, 3]);
      assertEditDistance(model, 3);
    });

    test('trunacte and add, sharing a contiguous block', () {
      var model = toObservable(['x', 'x', 'x', 'x', '1', '2', '3']);
      observeArray(model);
      model.length = 0;
      model.addAll(['1', '2', '3', 'y', 'y', 'y', 'y']);
      // Note: unlike the JS implementation, we don't perform a full diff.
      // The change records are computed with no regards to the *contents* of
      // the array. Thus, we get 14 instead of 8.
      assertEditDistance(model, 14);
    });

    test('truncate and add, sharing a discontiguous block', () {
      var model = toObservable(['1', '2', '3', '4', '5']);
      observeArray(model);
      model.length = 0;
      model.addAll(['a', '2', 'y', 'y', '4', '5', 'z', 'z']);
      // Note: unlike the JS implementation, we don't perform a full diff.
      // The change records are computed with no regards to the *contents* of
      // the array. Thus, we get 13 instead of 7.
      assertEditDistance(model, 13);
    });

    test('insert at beginning and end', () {
      var model = toObservable([2, 3, 4]);
      observeArray(model);
      model.insert(0, 5);
      model[2] = 6;
      model.add(7);
      assertEditDistance(model, 4);
    });
  });
}

_delta(i, r, a) => new ListChangeRecord(i, removedCount: r, addedCount: a);
_filter(records) => records.where((r) => r is ListChangeRecord).toList();
