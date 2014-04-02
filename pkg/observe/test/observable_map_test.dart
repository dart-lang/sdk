// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'observe_test_utils.dart';

main() => dirtyCheckZone().run(_runTests);

_runTests() {
  // TODO(jmesserly): need all standard Map API tests.

  StreamSubscription sub;

  sharedTearDown() {
    if (sub != null) {
      sub.cancel();
      sub = null;
    }
  }

  group('observe length', () {
    ObservableMap map;
    List<ChangeRecord> changes;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2, 'c': 3});
      changes = null;
      sub = map.changes.listen((records) {
        changes = getPropertyChangeRecords(records, #length);
      });
    });

    tearDown(sharedTearDown);

    test('add item changes length', () {
      map['d'] = 4;
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      return new Future(() {
        expectChanges(changes, [_lengthChange(map, 3, 4)]);
      });
    });

    test('putIfAbsent changes length', () {
      map.putIfAbsent('d', () => 4);
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      return new Future(() {
        expectChanges(changes, [_lengthChange(map, 3, 4)]);
      });
    });

    test('remove changes length', () {
      map.remove('c');
      map.remove('a');
      expect(map, {'b': 2});
      return new Future(() {
        expectChanges(changes, [
          _lengthChange(map, 3, 2),
          _lengthChange(map, 2, 1)
        ]);
      });
    });

    test('remove non-existent item does not change length', () {
      map.remove('d');
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      return new Future(() {
        expectChanges(changes, null);
      });
    });

    test('set existing item does not change length', () {
      map['c'] = 9000;
      expect(map, {'a': 1, 'b': 2, 'c': 9000});
      return new Future(() {
        expectChanges(changes, []);
      });
    });

    test('clear changes length', () {
      map.clear();
      expect(map, {});
      return new Future(() {
        expectChanges(changes, [_lengthChange(map, 3, 0)]);
      });
    });
  });

  group('observe item', () {

    ObservableMap map;
    List<ChangeRecord> changes;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2, 'c': 3});
      changes = null;
      sub = map.changes.listen((records) {
        changes = records.where((r) => r is MapChangeRecord && r.key == 'b')
            .toList();
      });
    });

    tearDown(sharedTearDown);

    test('putIfAbsent new item does not change existing item', () {
      map.putIfAbsent('d', () => 4);
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      return new Future(() {
        expectChanges(changes, []);
      });
    });

    test('set item to null', () {
      map['b'] = null;
      expect(map, {'a': 1, 'b': null, 'c': 3});
      return new Future(() {
        expectChanges(changes, [_changeKey('b', 2, null)]);
      });
    });

    test('set item to value', () {
      map['b'] = 777;
      expect(map, {'a': 1, 'b': 777, 'c': 3});
      return new Future(() {
        expectChanges(changes, [_changeKey('b', 2, 777)]);
      });
    });

    test('putIfAbsent does not change if already there', () {
      map.putIfAbsent('b', () => 1234);
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      return new Future(() {
        expectChanges(changes, null);
      });
    });

    test('change a different item', () {
      map['c'] = 9000;
      expect(map, {'a': 1, 'b': 2, 'c': 9000});
      return new Future(() {
      expectChanges(changes, []);
      });
    });

    test('change the item', () {
      map['b'] = 9001;
      map['b'] = 42;
      expect(map, {'a': 1, 'b': 42, 'c': 3});
      return new Future(() {
        expectChanges(changes, [
          _changeKey('b', 2, 9001),
          _changeKey('b', 9001, 42)
        ]);
      });
    });

    test('remove other items', () {
      map.remove('a');
      expect(map, {'b': 2, 'c': 3});
      return new Future(() {
        expectChanges(changes, []);
      });
    });

    test('remove the item', () {
      map.remove('b');
      expect(map, {'a': 1, 'c': 3});
      return new Future(() {
        expectChanges(changes, [_removeKey('b', 2)]);
      });
    });

    test('remove and add back', () {
      map.remove('b');
      map['b'] = 2;
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      return new Future(() {
        expectChanges(changes,
            [_removeKey('b', 2), _insertKey('b', 2)]);
      });
    });
  });

  test('toString', () {
    var map = toObservable({'a': 1, 'b': 2});
    expect(map.toString(), '{a: 1, b: 2}');
  });

  group('observe keys/values', () {
    ObservableMap map;
    int keysChanged;
    int valuesChanged;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2, 'c': 3});
      keysChanged = 0;
      valuesChanged = 0;
      sub = map.changes.listen((records) {
        keysChanged += getPropertyChangeRecords(records, #keys).length;
        valuesChanged += getPropertyChangeRecords(records, #values).length;
      });
    });

    tearDown(sharedTearDown);

    test('add item changes keys/values', () {
      map['d'] = 4;
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      return new Future(() {
        expect(keysChanged, 1);
        expect(valuesChanged, 1);
      });
    });

    test('putIfAbsent changes keys/values', () {
      map.putIfAbsent('d', () => 4);
      expect(map, {'a': 1, 'b': 2, 'c': 3, 'd': 4});
      return new Future(() {
        expect(keysChanged, 1);
        expect(valuesChanged, 1);
      });
    });

    test('remove changes keys/values', () {
      map.remove('c');
      map.remove('a');
      expect(map, {'b': 2});
      return new Future(() {
        expect(keysChanged, 2);
        expect(valuesChanged, 2);
      });
    });

    test('remove non-existent item does not change keys/values', () {
      map.remove('d');
      expect(map, {'a': 1, 'b': 2, 'c': 3});
      return new Future(() {
        expect(keysChanged, 0);
        expect(valuesChanged, 0);
      });
    });

    test('set existing item does not change keys', () {
      map['c'] = 9000;
      expect(map, {'a': 1, 'b': 2, 'c': 9000});
      return new Future(() {
        expect(keysChanged, 0);
        expect(valuesChanged, 1);
      });
    });

    test('clear changes keys/values', () {
      map.clear();
      expect(map, {});
      return new Future(() {
        expect(keysChanged, 1);
        expect(valuesChanged, 1);
      });
    });
  });


  group('change records', () {
    List<ChangeRecord> records;
    ObservableMap map;

    setUp(() {
      map = toObservable({'a': 1, 'b': 2});
      records = null;
      map.changes.first.then((r) { records = r; });
    });

    tearDown(sharedTearDown);

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
      return new Future(() {
        // no change from read-only operators
        expect(records, null);

        // Make a change so the subscription gets unregistered.
        map.clear();
      });
    });

    test('putIfAbsent', () {
      map.putIfAbsent('a', () => 42);
      expect(map, {'a': 1, 'b': 2});

      map.putIfAbsent('c', () => 3);
      expect(map, {'a': 1, 'b': 2, 'c': 3});

      return new Future(() {
        expectChanges(records, [
          _lengthChange(map, 2, 3),
          _insertKey('c', 3),
          _propChange(map, #keys),
          _propChange(map, #values),
        ]);
      });
    });

    test('[]=', () {
      map['a'] = 42;
      expect(map, {'a': 42, 'b': 2});

      map['c'] = 3;
      expect(map, {'a': 42, 'b': 2, 'c': 3});

      return new Future(() {
        expectChanges(records, [
          _changeKey('a', 1, 42),
          _propChange(map, #values),
          _lengthChange(map, 2, 3),
          _insertKey('c', 3),
          _propChange(map, #keys),
          _propChange(map, #values),
        ]);
      });
    });

    test('remove', () {
      map.remove('b');
      expect(map, {'a': 1});

      return new Future(() {
        expectChanges(records, [
          _removeKey('b', 2),
          _lengthChange(map, 2, 1),
          _propChange(map, #keys),
          _propChange(map, #values),
        ]);
      });
    });

    test('clear', () {
      map.clear();
      expect(map, {});

      return new Future(() {
        expectChanges(records, [
          _removeKey('a', 1),
          _removeKey('b', 2),
          _lengthChange(map, 2, 0),
          _propChange(map, #keys),
          _propChange(map, #values),
        ]);
      });
    });
  });
}

_lengthChange(map, int oldValue, int newValue) =>
    new PropertyChangeRecord(map, #length, oldValue, newValue);

_changeKey(key, old, newValue) => new MapChangeRecord(key, old, newValue);

_insertKey(key, newValue) => new MapChangeRecord.insert(key, newValue);

_removeKey(key, oldValue) => new MapChangeRecord.remove(key, oldValue);

_propChange(map, prop) => new PropertyChangeRecord(map, prop, null, null);
