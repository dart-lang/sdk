// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:logging/logging.dart';
import 'package:observe/observe.dart';
import 'package:observe/src/dirty_check.dart' as dirty_check;
import 'package:unittest/unittest.dart';
import 'observe_test_utils.dart';

const _VALUE = const Symbol('value');

main() {
  // Note: to test the basic Observable system, we use ObservableBox due to its
  // simplicity. We also test a variant that is based on dirty-checking.

  observeTest('no observers at the start', () {
    expect(dirty_check.allObservablesCount, 0);
  });

  group('WatcherModel', () { observeTests(watch: true); });

  group('ObservableBox', () { observeTests(); });

  group('dirtyCheck loops can be debugged', () {
    var messages;
    var subscription;
    setUp(() {
      messages = [];
      subscription = Logger.root.onRecord.listen((record) {
        messages.add(record.message);
      });
    });

    tearDown(() {
      subscription.cancel();
    });

    test('logs debug information', () {
      var maxNumIterations = dirty_check.MAX_DIRTY_CHECK_CYCLES;

      var x = new WatcherModel(0);
      var sub = x.changes.listen(expectAsync1((_) { x.value++; },
          count: maxNumIterations));
      x.value = 1;
      Observable.dirtyCheck();
      expect(x.value, maxNumIterations + 1);
      expect(messages.length, 2);

      expect(messages[0], contains('Possible loop'));
      expect(messages[1], contains('index 0'));
      expect(messages[1], contains('object: $x'));

      sub.cancel();
    });
  });
}

observeTests({bool watch: false}) {

  final createModel = watch ? (x) => new WatcherModel(x)
      : (x) => new ObservableBox(x);

  // Track the subscriptions so we can clean them up in tearDown.
  List subs;

  int initialObservers;
  setUp(() {
    initialObservers = dirty_check.allObservablesCount;
    subs = [];

    if (watch) runAsync(Observable.dirtyCheck);
  });

  tearDown(() {
    for (var sub in subs) sub.cancel();
    performMicrotaskCheckpoint();

    expect(dirty_check.allObservablesCount, initialObservers,
        reason: 'Observable object leaked');
  });

  observeTest('no observers', () {
    var t = createModel(123);
    expect(t.value, 123);
    t.value = 42;
    expect(t.value, 42);
    expect(t.hasObservers, false);
  });

  observeTest('listen adds an observer', () {
    var t = createModel(123);
    expect(t.hasObservers, false);

    subs.add(t.changes.listen((n) {}));
    expect(t.hasObservers, true);
  });

  observeTest('changes delived async', () {
    var t = createModel(123);
    int called = 0;

    subs.add(t.changes.listen(expectAsync1((records) {
      called++;
      expectChanges(records, _changedValue(watch ? 1 : 2));
    })));

    t.value = 41;
    t.value = 42;
    expect(called, 0);
  });

  observeTest('cause changes in handler', () {
    var t = createModel(123);
    int called = 0;

    subs.add(t.changes.listen(expectAsync1((records) {
      called++;
      expectChanges(records, _changedValue(1));
      if (called == 1) {
        // Cause another change
        t.value = 777;
      }
    }, count: 2)));

    t.value = 42;
  });

  observeTest('multiple observers', () {
    var t = createModel(123);

    verifyRecords(records) {
      expectChanges(records, _changedValue(watch ? 1 : 2));
    };

    subs.add(t.changes.listen(expectAsync1(verifyRecords)));
    subs.add(t.changes.listen(expectAsync1(verifyRecords)));

    t.value = 41;
    t.value = 42;
  });

  observeTest('performMicrotaskCheckpoint', () {
    var t = createModel(123);
    var records = [];
    subs.add(t.changes.listen((r) { records.addAll(r); }));
    t.value = 41;
    t.value = 42;
    expectChanges(records, [], reason: 'changes delived async');

    performMicrotaskCheckpoint();
    expectChanges(records, _changedValue(watch ? 1 : 2));
    records.clear();

    t.value = 777;
    expectChanges(records, [], reason: 'changes delived async');

    performMicrotaskCheckpoint();
    expectChanges(records, _changedValue(1));

    // Has no effect if there are no changes
    performMicrotaskCheckpoint();
    expectChanges(records, _changedValue(1));
  });

  observeTest('cancel listening', () {
    var t = createModel(123);
    var sub;
    sub = t.changes.listen(expectAsync1((records) {
      expectChanges(records, _changedValue(1));
      sub.cancel();
      t.value = 777;
      runAsync(Observable.dirtyCheck);
    }));
    t.value = 42;
  });

  observeTest('cancel and reobserve', () {
    var t = createModel(123);
    var sub;
    sub = t.changes.listen(expectAsync1((records) {
      expectChanges(records, _changedValue(1));
      sub.cancel();

      runAsync(expectAsync0(() {
        subs.add(t.changes.listen(expectAsync1((records) {
          expectChanges(records, _changedValue(1));
        })));
        t.value = 777;
        runAsync(Observable.dirtyCheck);
      }));
    }));
    t.value = 42;
  });

  observeTest('cannot modify changes list', () {
    var t = createModel(123);
    var records = null;
    subs.add(t.changes.listen((r) { records = r; }));
    t.value = 42;

    performMicrotaskCheckpoint();
    expectChanges(records, _changedValue(1));

    // Verify that mutation operations on the list fail:

    expect(() {
      records[0] = new PropertyChangeRecord(_VALUE);
    }, throwsUnsupportedError);

    expect(() { records.clear(); }, throwsUnsupportedError);

    expect(() { records.length = 0; }, throwsUnsupportedError);
  });

  observeTest('notifyChange', () {
    var t = createModel(123);
    var records = [];
    subs.add(t.changes.listen((r) { records.addAll(r); }));
    t.notifyChange(new PropertyChangeRecord(_VALUE));

    performMicrotaskCheckpoint();
    expectChanges(records, _changedValue(1));
    expect(t.value, 123, reason: 'value did not actually change.');
  });

  observeTest('notifyPropertyChange', () {
    var t = createModel(123);
    var records = null;
    subs.add(t.changes.listen((r) { records = r; }));
    expect(t.notifyPropertyChange(_VALUE, t.value, 42), 42,
        reason: 'notifyPropertyChange returns newValue');

    performMicrotaskCheckpoint();
    expectChanges(records, _changedValue(1));
    expect(t.value, 123, reason: 'value did not actually change.');
  });
}

_changedValue(len) => new List.filled(len, new PropertyChangeRecord(_VALUE));

// A test model based on dirty checking.
class WatcherModel<T> extends ObservableBase {
  @observable T value;

  WatcherModel([T initialValue]) : value = initialValue;

  String toString() => '#<$runtimeType value: $value>';
}
