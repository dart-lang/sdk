// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

main() {
  // TODO(jmesserly): need all standard Map API tests.

  group('observe length', () {
    ObservableMap map;
    List<ChangeRecord> changes;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2, 'c': 3});
      changes = null;
      map.changes.listen((records) {
        changes = records.where((r) => r.changes(_LENGTH)).toList();
      });
    });

    test('add item changes length', () {
      map['d'] = 4;
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      deliverChangeRecords();
      expectChanges(changes, [_lengthChange]);
    });

    test('putIfAbsent changes length', () {
      map.putIfAbsent('d', () => 4);
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      deliverChangeRecords();
      expectChanges(changes, [_lengthChange]);
    });

    test('remove changes length', () {
      map.remove('c');
      map.remove('a');
      expect(map, {'b': 2});
      deliverChangeRecords();
      expectChanges(changes, [_lengthChange, _lengthChange]);
    });

    test('remove non-existent item does not change length', () {
      map.remove('d');
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      deliverChangeRecords();
      expectChanges(changes, null);
    });

    test('set existing item does not change length', () {
      map['c'] = 9000;
      expect(map, {'a': 1, 'b': 2, 'c': 9000});
      deliverChangeRecords();
      expectChanges(changes, []);
    });

    test('clear changes length', () {
      map.clear();
      expect(map, {});
      deliverChangeRecords();
      expectChanges(changes, [_lengthChange]);
    });
  });

  group('observe item', () {

    ObservableMap map;
    List<ChangeRecord> changes;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2, 'c': 3});
      changes = null;
      map.changes.listen((records) {
        changes = records.where((r) => r.changes('b')).toList();
      });
    });

    test('putIfAbsent new item does not change existing item', () {
      map.putIfAbsent('d', () => 4);
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      deliverChangeRecords();
      expectChanges(changes, []);
    });

    test('set item to null', () {
      map['b'] = null;
      expect(map, {'a': 1, 'b': null, 'c': 3});
      deliverChangeRecords();
      expectChanges(changes, [_change('b')]);
    });

    test('set item to value', () {
      map['b'] = 777;
      expect(map, {'a': 1, 'b': 777, 'c': 3});
      deliverChangeRecords();
      expectChanges(changes, [_change('b')]);
    });

    test('putIfAbsent does not change if already there', () {
      map.putIfAbsent('b', () => 1234);
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      deliverChangeRecords();
      expectChanges(changes, null);
    });

    test('change a different item', () {
      map['c'] = 9000;
      expect(map, {'a': 1, 'b': 2, 'c': 9000});
      deliverChangeRecords();
      expectChanges(changes, []);
    });

    test('change the item', () {
      map['b'] = 9001;
      map['b'] = 42;
      expect(map, {'a': 1, 'b': 42, 'c': 3});
      deliverChangeRecords();
      expectChanges(changes, [_change('b'), _change('b')]);
    });

    test('remove other items', () {
      map.remove('a');
      expect(map, {'b': 2, 'c': 3});
      deliverChangeRecords();
      expectChanges(changes, []);
    });

    test('remove the item', () {
      map.remove('b');
      expect(map, {'a': 1, 'c': 3});
      deliverChangeRecords();
      expectChanges(changes, [_change('b', isRemove: true)]);
    });

    test('remove and add back', () {
      map.remove('b');
      map['b'] = 2;
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      deliverChangeRecords();
      expectChanges(changes,
          [_change('b', isRemove: true), _change('b', isInsert: true)]);
    });
  });

  test('toString', () {
    var map = toObservable({'a': 1, 'b': 2});
    expect(map.toString(), '{a: 1, b: 2}');
  });

  group('change records', () {
    List<ChangeRecord> records;
    ObservableMap map;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2});
      records = null;
      map.changes.first.then((r) { records = r; });
    });

    test('read operations', () {
      expect(map.length, 2);
      expect(map.isEmpty, false);
      expect(map['a'], 1);
      expect(map.containsKey(2), false);
      expect(map.containsValue(2), true);
      expect(map.containsKey('b'), true);
      expect(map.keys.toList(), ['a', 'b']);
      expect(map.values.toList(), [1, 2]);
      var copy = {};
      map.forEach((k, v) { copy[k] = v; });
      expect(copy, {'a': 1, 'b': 2});
      deliverChangeRecords();

      // no change from read-only operators
      expect(records, null);
    });

    test('putIfAbsent', () {
      map.putIfAbsent('a', () => 42);
      expect(map, {'a': 1, 'b': 2});

      map.putIfAbsent('c', () => 3);
      expect(map, {'a': 1, 'b': 2, 'c': 3});

      deliverChangeRecords();
      expectChanges(records, [
        _lengthChange,
        _change('c', isInsert: true),
      ]);
    });

    test('[]=', () {
      map['a'] = 42;
      expect(map, {'a': 42, 'b': 2});

      map['c'] = 3;
      expect(map, {'a': 42, 'b': 2, 'c': 3});

      deliverChangeRecords();
      expectChanges(records, [
        _change('a'),
        _lengthChange,
        _change('c', isInsert: true)
      ]);
    });

    test('remove', () {
      map.remove('b');
      expect(map, {'a': 1});

      deliverChangeRecords();
      expectChanges(records, [
        _change('b', isRemove: true),
        _lengthChange,
      ]);
    });

    test('clear', () {
      map.clear();
      expect(map, {});

      deliverChangeRecords();
      expectChanges(records, [
        _change('a', isRemove: true),
        _change('b', isRemove: true),
        _lengthChange,
      ]);
    });
  });
}


const _LENGTH = const Symbol('length');

final _lengthChange = new PropertyChangeRecord(_LENGTH);

_change(key, {isInsert: false, isRemove: false}) =>
    new MapChangeRecord(key, isInsert: isInsert, isRemove: isRemove);
