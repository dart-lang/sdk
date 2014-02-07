// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'observe_test_utils.dart';

main() => dirtyCheckZone().run(_runTests);

_runTests() {
  // TODO(jmesserly): need all standard List API tests.

  StreamSubscription sub, sub2;

  sharedTearDown() {
    list = null;
    sub.cancel();
    if (sub2 != null) {
      sub2.cancel();
      sub2 = null;
    }
  }

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

    test('add changes length', () {
      list.add(4);
      expect(list, [1, 2, 3, 4]);
      return new Future(() {
        expectChanges(changes, [_lengthChange(3, 4)]);
      });
    });

    test('removeObject', () {
      list.remove(2);
      expect(list, orderedEquals([1, 3]));

      return new Future(() {
        expectChanges(changes, [_lengthChange(3, 2)]);
      });
    });

    test('removeRange changes length', () {
      list.add(4);
      list.removeRange(1, 3);
      expect(list, [1, 4]);
      return new Future(() {
        expectChanges(changes, [_lengthChange(3, 4), _lengthChange(4, 2)]);
      });
    });

    test('length= changes length', () {
      list.length = 5;
      expect(list, [1, 2, 3, null, null]);
      return new Future(() {
        expectChanges(changes, [_lengthChange(3, 5)]);
      });
    });

    test('[]= does not change length', () {
      list[2] = 9000;
      expect(list, [1, 2, 9000]);
      return new Future(() {
        expectChanges(changes, null);
      });
    });

    test('clear changes length', () {
      list.clear();
      expect(list, []);
      return new Future(() {
        expectChanges(changes, [_lengthChange(3, 0)]);
      });
    });
  });

  group('observe index', () {
    List<ListChangeRecord> changes;

    setUp(() {
      list = toObservable([1, 2, 3]);
      changes = null;
      sub = list.listChanges.listen((records) {
        changes = getListChangeRecords(records, 1);
      });
    });

    tearDown(sharedTearDown);

    test('add does not change existing items', () {
      list.add(4);
      expect(list, [1, 2, 3, 4]);
      return new Future(() {
        expectChanges(changes, []);
      });
    });

    test('[]= changes item', () {
      list[1] = 777;
      expect(list, [1, 777, 3]);
      return new Future(() {
        expectChanges(changes, [_change(1, addedCount: 1, removed: [2])]);
      });
    });

    test('[]= on a different item does not fire change', () {
      list[2] = 9000;
      expect(list, [1, 2, 9000]);
      return new Future(() {
        expectChanges(changes, []);
      });
    });

    test('set multiple times results in one change', () {
      list[1] = 777;
      list[1] = 42;
      expect(list, [1, 42, 3]);
      return new Future(() {
        expectChanges(changes, [
          _change(1, addedCount: 1, removed: [2]),
        ]);
      });
    });

    test('set length without truncating item means no change', () {
      list.length = 2;
      expect(list, [1, 2]);
      return new Future(() {
        expectChanges(changes, []);
      });
    });

    test('truncate removes item', () {
      list.length = 1;
      expect(list, [1]);
      return new Future(() {
        expectChanges(changes, [_change(1, removed: [2, 3])]);
      });
    });

    test('truncate and add new item', () {
      list.length = 1;
      list.add(42);
      expect(list, [1, 42]);
      return new Future(() {
        expectChanges(changes, [
          _change(1, removed: [2, 3], addedCount: 1)
        ]);
      });
    });

    test('truncate and add same item', () {
      list.length = 1;
      list.add(2);
      expect(list, [1, 2]);
      return new Future(() {
        expectChanges(changes, []);
      });
    });
  });

  test('toString', () {
    var list = toObservable([1, 2, 3]);
    expect(list.toString(), '[1, 2, 3]');
  });

  group('change records', () {

    List<ChangeRecord> propRecords;
    List<ListChangeRecord> listRecords;

    setUp(() {
      list = toObservable([1, 2, 3, 1, 3, 4]);
      propRecords = null;
      listRecords = null;
      sub = list.changes.listen((r) { propRecords = r; });
      sub2 = list.listChanges.listen((r) { listRecords = r; });
    });

    tearDown(sharedTearDown);

    test('read operations', () {
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
      return new Future(() {
        // no change from read-only operators
        expectChanges(propRecords, null);
        expectChanges(listRecords, null);
      });
    });

    test('add', () {
      list.add(5);
      list.add(6);
      expect(list, orderedEquals([1, 2, 3, 1, 3, 4, 5, 6]));

      return new Future(() {
        expectChanges(propRecords, [
          _lengthChange(6, 7),
          _lengthChange(7, 8),
        ]);
        expectChanges(listRecords, [ _change(6, addedCount: 2) ]);
      });
    });

    test('[]=', () {
      list[1] = list.last;
      expect(list, orderedEquals([1, 4, 3, 1, 3, 4]));

      return new Future(() {
        expectChanges(propRecords, null);
        expectChanges(listRecords, [ _change(1, addedCount: 1, removed: [2]) ]);
      });
    });

    test('removeLast', () {
      expect(list.removeLast(), 4);
      expect(list, orderedEquals([1, 2, 3, 1, 3]));

      return new Future(() {
        expectChanges(propRecords, [_lengthChange(6, 5)]);
        expectChanges(listRecords, [_change(5, removed: [4])]);
      });
    });

    test('removeRange', () {
      list.removeRange(1, 4);
      expect(list, orderedEquals([1, 3, 4]));

      return new Future(() {
        expectChanges(propRecords, [_lengthChange(6, 3)]);
        expectChanges(listRecords, [_change(1, removed: [2, 3, 1])]);
      });
    });

    test('sort', () {
      list.sort((x, y) => x - y);
      expect(list, orderedEquals([1, 1, 2, 3, 3, 4]));

      return new Future(() {
        expectChanges(propRecords, null);
        expectChanges(listRecords, [
          _change(1, addedCount: 1),
          _change(4, removed: [1])
        ]);
      });
    });

    test('clear', () {
      list.clear();
      expect(list, []);

      return new Future(() {
        expectChanges(propRecords, [
            _lengthChange(6, 0),
            new PropertyChangeRecord(list, #isEmpty, false, true),
            new PropertyChangeRecord(list, #isNotEmpty, true, false),
        ]);
        expectChanges(listRecords, [_change(0, removed: [1, 2, 3, 1, 3, 4])]);
      });
    });
  });
}

ObservableList list;

_lengthChange(int oldValue, int newValue) =>
    new PropertyChangeRecord(list, #length, oldValue, newValue);

_change(index, {removed: const [], addedCount: 0}) => new ListChangeRecord(
    list, index, removed: removed, addedCount: addedCount);
