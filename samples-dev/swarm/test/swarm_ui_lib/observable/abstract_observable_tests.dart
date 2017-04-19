// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of observable_tests;

testAbstractObservable() {
  group('addChangeListener()', () {
    test('adding the same listener twice returns false the second time', () {
      final target = new AbstractObservable();
      final listener = (e) {};

      expect(target.addChangeListener(listener), isTrue);
      expect(target.addChangeListener(listener), isFalse);
    });

    test('modifies listeners list', () {
      // check that add/remove works, see contents of listeners too
      final target = new AbstractObservable();
      final l1 = (e) {};
      final l2 = (e) {};
      final l3 = (e) {};
      final l4 = (e) {};

      expect(target.listeners, orderedEquals([]));

      target.addChangeListener(l1);
      expect(target.listeners, orderedEquals([l1]));

      target.addChangeListener(l2);
      expect(target.listeners, orderedEquals([l1, l2]));

      target.addChangeListener(l3);
      target.addChangeListener(l4);
      expect(target.listeners, orderedEquals([l1, l2, l3, l4]));

      target.removeChangeListener(l4);
      expect(target.listeners, orderedEquals([l1, l2, l3]));

      target.removeChangeListener(l2);
      expect(target.listeners, orderedEquals([l1, l3]));

      target.removeChangeListener(l1);
      expect(target.listeners, orderedEquals([l3]));

      target.removeChangeListener(l3);
      expect(target.listeners, orderedEquals([]));
    });
  });

  test('fires immediately if no batch', () {
    // If no batch is created, a summary should be automatically created and
    // fired on each property change.
    final target = new AbstractObservable();
    EventSummary res = null;
    target.addChangeListener((summary) {
      expect(res, isNull);
      res = summary;
      expect(res, isNotNull);
    });

    target.recordPropertyUpdate('pM', 10, 11);

    expect(res, isNotNull);
    expect(res.events, hasLength(1));
    validateUpdate(res.events[0], target, 'pM', null, 10, 11);
    res = null;

    target.recordPropertyUpdate('pL', '11', '13');

    expect(res, isNotNull);
    expect(res.events, hasLength(1));
    validateUpdate(res.events[0], target, 'pL', null, '11', '13');
  });
}
