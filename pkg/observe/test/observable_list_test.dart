// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'observe_test_utils.dart';

main() {
  // TODO(jmesserly): need all standard List API tests.

  StreamSubscription sub;

  sharedTearDown() { sub.cancel(); }

  group('observe length', () {

    ObservableList list;
    List<ChangeRecord> changes;

    setUp(() {
      list = toObservable([1, 2, 3]);
      changes = null;
      sub = list.changes.listen((records) {
        changes = getPropertyChangeRecords(records, #length);
      });
    });

    tearDown(sharedTearDown);

    observeTest('add changes length', () {
      list.add(4);
      expect(list, [1, 2, 3, 4]);
      performMicrotaskCheckpoint();
      expectChanges(changes, [_lengthChange(list, 3, 4)]);
    });

    observeTest('removeObject', () {
      list.remove(2);
      expect(list, orderedEquals([1, 3]));

      performMicrotaskCheckpoint();
      expectChanges(changes, [_lengthChange(list, 3, 2)]);
    });

    observeTest('removeRange changes length', () {
      list.add(4);
      list.removeRange(1, 3);
      expect(list, [1, 4]);
      performMicrotaskCheckpoint();
      expectChanges(changes, [_lengthChange(list, 3, 2)]);
    });

    observeTest('length= changes length', () {
      list.length = 5;
      expect(list, [1, 2, 3, null, null]);
      performMicrotaskCheckpoint();
      expectChanges(changes, [_lengthChange(list, 3, 5)]);
    });

    observeTest('[]= does not change length', () {
      list[2] = 9000;
      expect(list, [1, 2, 9000]);
      performMicrotaskCheckpoint();
      expectChanges(changes, []);
    });

    observeTest('clear changes length', () {
      list.clear();
      expect(list, []);
      performMicrotaskCheckpoint();
      expectChanges(changes, [_lengthChange(list, 3, 0)]);
    });
  });

  group('observe index', () {
    ObservableList list;
    List<ChangeRecord> changes;

    setUp(() {
      list = toObservable([1, 2, 3]);
      changes = null;
      sub = list.changes.listen((records) {
        changes = getListChangeRecords(records, 1);
      });
    });

    tearDown(sharedTearDown);

    observeTest('add does not change existing items', () {
      list.add(4);
      expect(list, [1, 2, 3, 4]);
      performMicrotaskCheckpoint();
      expectChanges(changes, []);
    });

    observeTest('[]= changes item', () {
      list[1] = 777;
      expect(list, [1, 777, 3]);
      performMicrotaskCheckpoint();
      expectChanges(changes, [_change(1, addedCount: 1, removedCount: 1)]);
    });

    observeTest('[]= on a different item does not fire change', () {
      list[2] = 9000;
      expect(list, [1, 2, 9000]);
      performMicrotaskCheckpoint();
      expectChanges(changes, []);
    });

    observeTest('set multiple times results in one change', () {
      list[1] = 777;
      list[1] = 42;
      expect(list, [1, 42, 3]);
      performMicrotaskCheckpoint();
      expectChanges(changes, [
        _change(1, addedCount: 1, removedCount: 1),
      ]);
    });

    observeTest('set length without truncating item means no change', () {
      list.length = 2;
      expect(list, [1, 2]);
      performMicrotaskCheckpoint();
      expectChanges(changes, []);
    });

    observeTest('truncate removes item', () {
      list.length = 1;
      expect(list, [1]);
      performMicrotaskCheckpoint();
      expectChanges(changes, [_change(1, removedCount: 2)]);
    });

    observeTest('truncate and add new item', () {
      list.length = 1;
      list.add(42);
      expect(list, [1, 42]);
      performMicrotaskCheckpoint();
      expectChanges(changes, [
        _change(1, removedCount: 2, addedCount: 1)
      ]);
    });

    observeTest('truncate and add same item', () {
      list.length = 1;
      list.add(2);
      expect(list, [1, 2]);
      performMicrotaskCheckpoint();
      expectChanges(changes, [
        _change(1, removedCount: 2, addedCount: 1)
      ]);
    });
  });

  observeTest('toString', () {
    var list = toObservable([1, 2, 3]);
    expect(list.toString(), '[1, 2, 3]');
  });

  group('change records', () {

    List<ChangeRecord> records;
    ObservableList list;

    setUp(() {
      list = toObservable([1, 2, 3, 1, 3, 4]);
      records = null;
      sub = list.changes.listen((r) { records = r; });
    });

    tearDown(sharedTearDown);

    observeTest('read operations', () {
      expect(list.length, 6);
      expect(list[0], 1);
      expect(list.indexOf(4), 5);
      expect(list.indexOf(1), 0);
      expect(list.indexOf(1, 1), 3);
      expect(list.lastIndexOf(1), 3);
      expect(list.last, 4);
      var copy = new List<int>();
      list.forEach((i) { copy.add(i); });
      expect(copy, orderedEquals([1, 2, 3, 1, 3, 4]));
      performMicrotaskCheckpoint();

      // no change from read-only operators
      expectChanges(records, null);
    });

    observeTest('add', () {
      list.add(5);
      list.add(6);
      expect(list, orderedEquals([1, 2, 3, 1, 3, 4, 5, 6]));

      performMicrotaskCheckpoint();
      expectChanges(records, [
        _lengthChange(list, 6, 8),
        _change(6, addedCount: 2)
      ]);
    });

    observeTest('[]=', () {
      list[1] = list.last;
      expect(list, orderedEquals([1, 4, 3, 1, 3, 4]));

      performMicrotaskCheckpoint();
      expectChanges(records, [ _change(1, addedCount: 1, removedCount: 1) ]);
    });

    observeTest('removeLast', () {
      expect(list.removeLast(), 4);
      expect(list, orderedEquals([1, 2, 3, 1, 3]));

      performMicrotaskCheckpoint();
      expectChanges(records, [
        _lengthChange(list, 6, 5),
        _change(5, removedCount: 1)
      ]);
    });

    observeTest('removeRange', () {
      list.removeRange(1, 4);
      expect(list, orderedEquals([1, 3, 4]));

      performMicrotaskCheckpoint();
      expectChanges(records, [
        _lengthChange(list, 6, 3),
        _change(1, removedCount: 3),
      ]);
    });

    observeTest('sort', () {
      list.sort((x, y) => x - y);
      expect(list, orderedEquals([1, 1, 2, 3, 3, 4]));

      performMicrotaskCheckpoint();
      expectChanges(records, [
        _change(1, addedCount: 5, removedCount: 5),
      ]);
    });

    observeTest('clear', () {
      list.clear();
      expect(list, []);

      performMicrotaskCheckpoint();
      expectChanges(records, [
        _lengthChange(list, 6, 0),
        _change(0, removedCount: 6)
      ]);
    });
  });
}

_lengthChange(list, int oldValue, int newValue) =>
    new PropertyChangeRecord(list, #length, oldValue, newValue);

_change(index, {removedCount: 0, addedCount: 0}) => new ListChangeRecord(
    index, removedCount: removedCount, addedCount: addedCount);
