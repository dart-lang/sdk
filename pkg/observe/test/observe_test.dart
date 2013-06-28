// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:observe/observe.dart';
import 'package:unittest/unittest.dart';
import 'utils.dart';

main() {
  // Note: to test the basic Observable system, we use ObservableBox due to its
  // simplicity.

  const _VALUE = const Symbol('value');

  group('ObservableBox', () {
    test('no observers', () {
      var t = new ObservableBox<int>(123);
      expect(t.value, 123);
      t.value = 42;
      expect(t.value, 42);
      expect(t.hasObservers, false);
    });

    test('listen adds an observer', () {
      var t = new ObservableBox<int>(123);
      expect(t.hasObservers, false);

      t.changes.listen((n) {});
      expect(t.hasObservers, true);
    });

    test('changes delived async', () {
      var t = new ObservableBox<int>(123);
      int called = 0;

      t.changes.listen(expectAsync1((records) {
        called++;
        expectChanges(records, [_record(_VALUE), _record(_VALUE)]);
      }));
      t.value = 41;
      t.value = 42;
      expect(called, 0);
    });

    test('cause changes in handler', () {
      var t = new ObservableBox<int>(123);
      int called = 0;

      t.changes.listen(expectAsync1((records) {
        called++;
        expectChanges(records, [_record(_VALUE)]);
        if (called == 1) {
          // Cause another change
          t.value = 777;
        }
      }, count: 2));

      t.value = 42;
    });

    test('multiple observers', () {
      var t = new ObservableBox<int>(123);

      verifyRecords(records) {
        expectChanges(records, [_record(_VALUE), _record(_VALUE)]);
      };

      t.changes.listen(expectAsync1(verifyRecords));
      t.changes.listen(expectAsync1(verifyRecords));

      t.value = 41;
      t.value = 42;
    });

    test('deliverChangeRecords', () {
      var t = new ObservableBox<int>(123);
      var records = [];
      t.changes.listen((r) { records.addAll(r); });
      t.value = 41;
      t.value = 42;
      expectChanges(records, [], reason: 'changes delived async');

      deliverChangeRecords();
      expectChanges(records,
          [_record(_VALUE), _record(_VALUE)]);
      records.clear();

      t.value = 777;
      expectChanges(records, [], reason: 'changes delived async');

      deliverChangeRecords();
      expectChanges(records, [_record(_VALUE)]);

      // Has no effect if there are no changes
      deliverChangeRecords();
      expectChanges(records, [_record(_VALUE)]);
    });

    test('cancel listening', () {
      var t = new ObservableBox<int>(123);
      var sub;
      sub = t.changes.listen(expectAsync1((records) {
        expectChanges(records, [_record(_VALUE)]);
        sub.cancel();
        t.value = 777;
      }));
      t.value = 42;
    });

    test('cancel and reobserve', () {
      var t = new ObservableBox<int>(123);
      var sub;
      sub = t.changes.listen(expectAsync1((records) {
        expectChanges(records, [_record(_VALUE)]);
        sub.cancel();

        runAsync(expectAsync0(() {
          sub = t.changes.listen(expectAsync1((records) {
            expectChanges(records, [_record(_VALUE)]);
          }));
          t.value = 777;
        }));
      }));
      t.value = 42;
    });
  });
}

_record(key) => new PropertyChangeRecord(key);
