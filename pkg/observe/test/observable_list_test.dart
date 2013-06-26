// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

main() {
  // TODO(jmesserly): need all standard List API tests.

  const _LENGTH = const Symbol('length');

  group('observe length', () {

    ObservableList list;
    List<ChangeRecord> changes;

    setUp(() {
      list = toObservable([1, 2, 3]);
      changes = null;
      list.changes.listen((records) {
        changes = records.where((r) => r.changes(_LENGTH)).toList();
      });
    });

    test('add changes length', () {
      list.add(4);
      expect(list, [1, 2, 3, 4]);
      deliverChangeRecords();
      expectChanges(changes, [_lengthChange]);
    });

    test('removeRange changes length', () {
      list.add(4);
      list.removeRange(1, 3);
      expect(list, [1, 4]);
      deliverChangeRecords();
      expectChanges(changes, [_lengthChange]);
    });

    test('length= changes length', () {
      list.length = 5;
      expect(list, [1, 2, 3, null, null]);
      deliverChangeRecords();
      expectChanges(changes, [_lengthChange]);
    });

    test('[]= does not change length', () {
      list[2] = 9000;
      expect(list, [1, 2, 9000]);
      deliverChangeRecords();
      expectChanges(changes, []);
    });

    test('clear changes length', () {
      list.clear();
      expect(list, []);
      deliverChangeRecords();
      expectChanges(changes, [_lengthChange]);
    });
  });

  group('observe index', () {
    ObservableList list;
    List<ChangeRecord> changes;

    setUp(() {
      list = toObservable([1, 2, 3]);
      changes = null;
      list.changes.listen((records) {
        changes = records.where((r) => r.changes(1)).toList();
      });
    });

    test('add does not change existing items', () {
      list.add(4);
      expect(list, [1, 2, 3, 4]);
      deliverChangeRecords();
      expectChanges(changes, []);
    });

    test('[]= changes item', () {
      list[1] = 777;
      expect(list, [1, 777, 3]);
      deliverChangeRecords();
      expectChanges(changes, [_change(1, addedCount: 1, removedCount: 1)]);
    });

    test('[]= on a different item does not fire change', () {
      list[2] = 9000;
      expect(list, [1, 2, 9000]);
      deliverChangeRecords();
      expectChanges(changes, []);
    });

    test('set multiple times results in one change', () {
      list[1] = 777;
      list[1] = 42;
      expect(list, [1, 42, 3]);
      deliverChangeRecords();
      expectChanges(changes, [
        _change(1, addedCount: 1, removedCount: 1),
      ]);
    });

    test('set length without truncating item means no change', () {
      list.length = 2;
      expect(list, [1, 2]);
      deliverChangeRecords();
      expectChanges(changes, []);
    });

    test('truncate removes item', () {
      list.length = 1;
      expect(list, [1]);
      deliverChangeRecords();
      expectChanges(changes, [_change(1, removedCount: 2)]);
    });

    test('truncate and add new item', () {
      list.length = 1;
      list.add(42);
      expect(list, [1, 42]);
      deliverChangeRecords();
      expectChanges(changes, [
        _change(1, removedCount: 2, addedCount: 1)
      ]);
    });

    test('truncate and add same item', () {
      list.length = 1;
      list.add(2);
      expect(list, [1, 2]);
      deliverChangeRecords();
      expectChanges(changes, [
        _change(1, removedCount: 2, addedCount: 1)
      ]);
    });
  });

  test('toString', () {
    var list = toObservable([1, 2, 3]);
    expect(list.toString(), '[1, 2, 3]');
  });

  group('change records', () {

    List<ChangeRecord> records;
    ObservableList list;

    setUp(() {
      list = toObservable([1, 2, 3, 1, 3, 4]);
      records = null;
      list.changes.listen((r) { records = r; });
    });

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
      deliverChangeRecords();

      // no change from read-only operators
      expectChanges(records, null);
    });

    test('add', () {
      list.add(5);
      list.add(6);
      expect(list, orderedEquals([1, 2, 3, 1, 3, 4, 5, 6]));

      deliverChangeRecords();
      expectChanges(records, [
        _lengthChange,
        _change(6, addedCount: 2)
      ]);
    });

    test('[]=', () {
      list[1] = list.last;
      expect(list, orderedEquals([1, 4, 3, 1, 3, 4]));

      deliverChangeRecords();
      expectChanges(records, [ _change(1, addedCount: 1, removedCount: 1) ]);
    });

    test('removeLast', () {
      expect(list.removeLast(), 4);
      expect(list, orderedEquals([1, 2, 3, 1, 3]));

      deliverChangeRecords();
      expectChanges(records, [
        _lengthChange,
        _change(5, removedCount: 1)
      ]);
    });

    test('removeRange', () {
      list.removeRange(1, 4);
      expect(list, orderedEquals([1, 3, 4]));

      deliverChangeRecords();
      expectChanges(records, [
        _lengthChange,
        _change(1, removedCount: 3),
      ]);
    });

    test('sort', () {
      list.sort((x, y) => x - y);
      expect(list, orderedEquals([1, 1, 2, 3, 3, 4]));

      deliverChangeRecords();
      expectChanges(records, [
        _change(1, addedCount: 5, removedCount: 5),
      ]);
    });

    test('clear', () {
      list.clear();
      expect(list, []);

      deliverChangeRecords();
      expectChanges(records, [
        _lengthChange,
        _change(0, removedCount: 6)
      ]);
    });
  });
}

const _LENGTH = const Symbol('length');

final _lengthChange = new PropertyChangeRecord(_LENGTH);

_change(index, {removedCount: 0, addedCount: 0}) => new ListChangeRecord(
    index, removedCount: removedCount, addedCount: addedCount);
